#import "MenusHeaderView.h"
#import "MenusSelectionView.h"
#import "Blog.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"

@interface MenusHeaderView () <MenusSelectionViewDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *locationsView;
@property (nonatomic, weak) IBOutlet MenusSelectionView *menusView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

static CGFloat const MenusHeaderViewDesignStrokeWidth = 2.0;

@implementation MenusHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // provide extra margin to easily draw the design stroke, see drawRect:
    UIEdgeInsets margins = MenusDesignDefaultInsets();
    margins.bottom += MenusHeaderViewDesignStrokeWidth;
    self.stackView.layoutMargins = margins;
    self.stackView.layoutMarginsRelativeArrangement = YES;
    self.stackView.spacing = margins.left; // use a relative spacing to our margin padding
    
    self.backgroundColor = [WPStyleGuide lightGrey];
    self.textLabel.font = [WPStyleGuide subtitleFont];
    self.textLabel.backgroundColor = [UIColor clearColor];
    
    self.locationsView.delegate = self;
    self.menusView.delegate = self;
}

- (void)updateWithMenusForBlog:(Blog *)blog
{
    {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:blog.menuLocations.count];
        for(MenuLocation *location in blog.menuLocations) {
            MenusSelectionViewItem *item = [MenusSelectionViewItem itemWithLocation:location];
            [items addObject:item];
        }
        
        [self.locationsView setAvailableSelectionItems:items];
        [self.locationsView setSelectedItem:[items firstObject]];
    }
    {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:blog.menus.count];
        for(Menu *menu in blog.menus) {
            MenusSelectionViewItem *item = [MenusSelectionViewItem itemWithMenu:menu];
            [items addObject:item];
        }
        
        [self.menusView setAvailableSelectionItems:items];
        [self.menusView setSelectedItem:[items firstObject]];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if(self.stackView.axis == UILayoutConstraintAxisHorizontal) {
        // toggle the selection on a trait collection change to a horizonal axis for the stack view
        // this ensures both selection views are expanded if one already is
        // otherwise the design looks odd with too much negative space
        // see userInteractionDetectedForTogglingSelectionView:expand:
        if(self.locationsView.selectionExpanded || self.menusView.selectionExpanded) {
            if(self.locationsView.selectionExpanded && !self.menusView.selectionExpanded) {
                
                [self.menusView setSelectionItemsExpanded:YES animated:NO];
                
            }else if(self.menusView.selectionExpanded && !self.locationsView.selectionExpanded) {
             
                [self.locationsView setSelectionItemsExpanded:YES animated:NO];
            }
        }
    }
    
    // required to redraw the stroke because our intrinsicContentSize changed based on the stack view axis change
    // perhaps this won't be needed in a future version of iOS
    // via Brent Coursey 10/30/15
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, MenusHeaderViewDesignStrokeWidth);
    
    const CGFloat lineY = rect.size.height - (MenusHeaderViewDesignStrokeWidth / 2);
    CGContextMoveToPoint(context, rect.origin.x, lineY);
    CGContextAddLineToPoint(context, rect.size.width - rect.origin.x, lineY);
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten20] CGColor]);
    CGContextStrokePath(context);
}

#pragma mark - private

- (void)closeSelectionsIfNeeded
{
    // add a UX delay to selection close animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.locationsView setSelectionItemsExpanded:NO animated:YES];
        [self.menusView setSelectionItemsExpanded:NO animated:YES];
    });
}

#pragma mark - delegate helpers

- (void)tellDelegateSelectedLocation:(MenuLocation *)location
{
    [self.delegate headerViewSelectionChangedWithSelectedLocation:location];
}

- (void)tellDelegateSelectedMenu:(Menu *)menu
{
    [self.delegate headerViewSelectionChangedWithSelectedMenu:menu];
}

#pragma mark - MenusSelectionViewDelegate

- (void)userInteractionDetectedForTogglingSelectionView:(MenusSelectionView *)selectionView expand:(BOOL)expand
{
    if(self.stackView.axis == UILayoutConstraintAxisHorizontal) {
        // in the horizontal axis we want to toggle expansion for both selection views
        // otherwise the design looks odd with too much negative space
        // see traitCollectionDidChange:
        if(selectionView == self.locationsView) {
            [self.menusView setSelectionItemsExpanded:expand animated:YES];
        }else if(selectionView == self.menusView) {
            [self.locationsView setSelectionItemsExpanded:expand animated:YES];
        }
        
        [selectionView setSelectionItemsExpanded:expand animated:YES];
        
    }else {
        [selectionView setSelectionItemsExpanded:expand animated:YES];
    }
}

- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionViewItem *)item
{
    if([item isMenuLocation]) {
        [self tellDelegateSelectedLocation:item.itemObject];
    }else if([item isMenu]) {
        [self tellDelegateSelectedMenu:item.itemObject];
    }
    [self closeSelectionsIfNeeded];
}

@end
