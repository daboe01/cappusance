@import "GSMarkupTagView.j"

@implementation GSMarkupTagFlashView : GSMarkupTagView
+ (CPString) tagName
{
  return @"flashView";
}

+ (Class) platformObjectClass
{
  return [CPFlashView class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];

    var name = [_attributes objectForKey: @"ressource"];

    if (name != nil)
	{	[platformObject setFlashMovie: [CPFlashMovie flashMovieWithFile: [CPString stringWithFormat:@"%@/%@", [[CPBundle mainBundle] resourcePath], name ]] ];
	}

	return platformObject;
}
@end


@implementation GSMarkupTagLevelIndicator : GSMarkupTagControl
+ (CPString) tagName
{
  return @"levelIndicator";
}

+ (Class) platformObjectClass
{
  return [CPLevelIndicator class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];

	var min;
	var max;
	var warning;
	var critical;
	var current;

	min = [_attributes objectForKey: @"min"];
	if (min != nil)
    {	[platformObject setMinValue: [min doubleValue]];
    }

	max = [_attributes objectForKey: @"max"];
	if (max != nil)
    {	[platformObject setMaxValue: [max doubleValue]];
    }
	warning = [_attributes objectForKey: @"warning"];
	if (warning != nil)
    {	[platformObject setWarningValue: [warning doubleValue]];
    }
	critical = [_attributes objectForKey: @"critical"];
	if (critical != nil)
    {	[platformObject setCriticalValue: [critical doubleValue]];
    }

  /* minimum size is 83x17*/
	var height;
	height = [_attributes objectForKey: @"height"];
	if (height == nil)
	{
		[_attributes setObject: @"25" forKey: @"height"];
	}
	var width;
	width = [_attributes objectForKey: @"width"];
	if (width == nil)
    {	[_attributes setObject: @"250" forKey: @"width"];
    }

	return platformObject;
}
@end

@implementation GSMarkupTagStepper : GSMarkupTagLevelIndicator
+ (CPString) tagName
{
  return @"stepper";
}

+ (Class) platformObjectClass
{
  return [CPStepper class];
}

@end


//<!> fixme: only small spinner is currently supported
@implementation GSMarkupTagProgresIndicator : GSMarkupTagLevelIndicator
+ (CPString) tagName
{
  return @"progresIndicator";
}

+ (Class) platformObjectClass
{
  return [CPProgressIndicator class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	var current;

	[platformObject setDisplayedWhenStopped:NO];
	[platformObject setStyle:CPProgressIndicatorSpinningStyle];
	[platformObject setControlSize:CPMiniControlSize];
	[_attributes setObject: @"16" forKey: @"height"];
	[_attributes setObject: @"16" forKey: @"width"];
	return platformObject;
}
@end


@implementation GSMarkupOperator: GSMarkupTagObject

+ (CPString) tagName
{
  return @"operator";
}
-(CPArray) content
{	return _content;
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
-(CPNumber) operator
{	var type= [_attributes objectForKey:"type"];
	if( type == "equal") return [CPNumber numberWithInt: CPEqualToPredicateOperatorType];
	else if( type == "begins") return [CPNumber numberWithInt: CPBeginsWithPredicateOperatorType];
	else if( type == "ends") return [CPNumber numberWithInt: CPEndsWithPredicateOperatorType];
	return nil
}
@end


@implementation GSMarkupLexpression: GSMarkupTagObject

+ (CPString) tagName
{
  return @"lexpression";
}
-(CPArray) content
{	return _content;
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
-(CPString) keyPath
{	return [_attributes objectForKey:"keyPath"];
}
@end

@implementation GSMarkupRexpression: GSMarkupTagObject

+ (CPString) tagName
{
  return @"rexpression";
}
-(CPArray) content
{	return _content;
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
-(CPString) keyPath
{	return [_attributes objectForKey:"keyPath"];
}
@end


@implementation GSMarkupRowTemplate: GSMarkupTagObject

+ (CPString) tagName
{
  return @"rowTemplate";
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
@end

@import <AppKit/CPPredicateEditor.j>

@implementation CPPredicateEditor(SizeToFitFix)
-(void) sizeToFit
{
}
@end

@implementation GSMarkupTagPredicateEditor : GSMarkupTagView
+ (CPString) tagName
{	return @"predicateEditor";
}

+ (Class) platformObjectClass
{	return [CPPredicateEditor class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];

// now extract columns and PK...
	var rowTemplates=[CPMutableArray new];
    var i, count = _content?_content.length:0;
	for (i = 0 ; i < count; i++)
	{	var v = _content[i];
		if([v isKindOfClass: [GSMarkupRowTemplate class] ])
		{	var expressions=[v content];
			var j,l1=expressions.length;
			var lexpressions=[CPMutableArray new];
			var ops=[CPMutableArray new];
			for(j=0;j<l1;j++)
			{	var expr=expressions[j];
				if([expr isKindOfClass: [GSMarkupLexpression class] ])
					[lexpressions addObject: [CPExpression expressionForKeyPath: [expr keyPath] ]];
				else if([expr isKindOfClass: [GSMarkupOperator class] ])
					 if([expr operator]) [ops addObject: [expr operator]];
			}
			var rowTemplate=[[CPPredicateEditorRowTemplate alloc]
				 initWithLeftExpressions: lexpressions
			rightExpressionAttributeType: CPStringAttributeType		//<!> fixme
								modifier: 0	//<!> fixme
							   operators: ops
								 options: 0];	//<!> fixme
			[rowTemplates addObject: rowTemplate];
		}
	}

	[platformObject setNestingMode: CPRuleEditorNestingModeCompound];
	[rowTemplates addObject: [ [CPPredicateEditorRowTemplate alloc] initWithCompoundTypes:
			[CPArray arrayWithObjects: [CPNumber numberWithInt: CPAndPredicateType], [CPNumber numberWithInt: CPOrPredicateType], [CPNumber numberWithInt: CPNotPredicateType]  ] ] ];
	[platformObject setRowTemplates: rowTemplates];
	[platformObject setFormattingStringsFilename: nil];	// fixes capp issue
	return platformObject;
}
@end

@implementation GSMarkupTagPredicate : GSMarkupTagObject
+ (CPString) tagName
{	return @"predicate";
}

+ (Class) platformObjectClass
{	return nil;
}

- (id) initPlatformObject: (id)platformObject
{	platformObject=[CPPredicate predicateWithFormat: [_attributes objectForKey:"format"] argumentArray: nil ];
	return platformObject;
}
@end

@implementation GSMarkupTagTabViewItem : GSMarkupTagObject
+ (CPString) tagName
{
  return @"tabViewItem";
}

+ (Class) platformObjectClass
{
  return nil;
}

-(CPString) title
{	return [_attributes objectForKey:"title"];
}
- (id) initPlatformObject: (id)platformObject
{	platformObject=[[CPTabViewItem alloc] initWithIdentifier: [self title] ];
	return platformObject;
}
@end

@import <AppKit/CPTabView.j>

@implementation GSMarkupTagTabView : GSMarkupTagView
+ (CPString) tagName
{
  return @"tabView";
}

+ (Class) platformObjectClass
{
  return [CPTabView class];
}

-(int) type
{	if([_attributes objectForKey: "type"]=="topBezel") return CPTopTabsBezelBorder;
	return CPNoTabsBezelBorder;
}
- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	[platformObject setTabViewType: [self type]];

    var  i, count = _content? _content.length:0;
	for (i = 0 ; i < count; i++)
	{	var item = [_content[i] platformObject];
        [item setView: [[_content[i] content][0] platformObject] ];
        [item setLabel: [_content[i] title] ];
		[platformObject addTabViewItem: item];
	}
	return platformObject;
}
@end

@implementation  CPTabView(AutoLayoutDefaults)
- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{	return GSAutoLayoutExpand;
}
- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{	return GSAutoLayoutExpand;
}

@end

@import "GSMarkupTagControl.j"
@implementation GSMarkupTagCheckBox : GSMarkupTagControl
+ (CPString) tagName
{
  return @"checkBox";
}

+ (Class) platformObjectClass
{
  return [CPCheckBox class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	[platformObject setTitle: [_attributes objectForKey:"title"] ];
	return platformObject;
}
@end

@import <AppKit/CPCollectionView.j>

@implementation CPCollectionView(KVB)
-(void) setObjectValue: someArray
{	[self setContent: someArray];
}
-(CPArray) value
{	return [self content];
}
-(void) setValue:(CPArray) someArray
{	return [self setObjectValue: someArray];
}
- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{	return GSAutoLayoutExpand;
}
- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{	return GSAutoLayoutExpand;
}

- (void)performDragOperation:(CPDraggingInfo)aSender
{
    [_delegate performDragOperation: aSender];
    
}

@end

@implementation GSMarkupTagCollectionView : GSMarkupTagView
+ (CPString) tagName
{
  return @"collectionView";
}

+ (Class) platformObjectClass
{
  return [CPCollectionView class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	[platformObject setSelectable: [self boolValueForAttribute:"selectable"]==1 ];

	[platformObject setAllowsEmptySelection: [self boolValueForAttribute:"emptySelectionAllowed"]==1 ];
	[platformObject setAllowsMultipleSelection: [self boolValueForAttribute:"multipleSelectionAllowed"]!=0 ];
	[platformObject setMaxNumberOfRows: [self intValueForAttribute:"maxRows"] ];
	[platformObject setMaxNumberOfColumns: [self intValueForAttribute:"maxColumns"] ];
	var width=[self intValueForAttribute:"itemWidth"];
	var height=[self intValueForAttribute:"itemHeight"];
	if(width && height)
	{	var mysize=CPMakeSize(width,height);
		[platformObject setMinItemSize: mysize ];
		[platformObject setMaxItemSize: mysize ];
	}
	var width=[self intValueForAttribute:"minItemWidth"];
	var height=[self intValueForAttribute:"minItemHeight"];
	if(width && height)
	{	[platformObject setMinItemSize: CPMakeSize(width,height) ];
	}
	var width=[self intValueForAttribute:"maxItemWidth"];
	var height=[self intValueForAttribute:"maxItemHeight"];
	if(width && height)
	{	[platformObject setMaxItemSize: CPMakeSize(width,height) ];
	}
	var protoClass=CPClassFromString([self stringValueForAttribute:"itemsClassName"]);
	if(!protoClass) protoClass=[CPCollectionViewItem class];
	var proto=[protoClass new];
	var peek;
	[platformObject setItemPrototype: proto];
	return platformObject;
}

- (id) postInitPlatformObject: (id)platformObject
{	platformObject=[super postInitPlatformObject: platformObject];
	[platformObject tile];
	return platformObject;
}
@end

@import <AppKit/CPButtonBar.j>
@implementation GSMarkupTagButtonBar : GSMarkupTagView
+ (CPString) tagName
{
  return @"ButtonBar";
}

+ (Class) platformObjectClass
{
  return [CPButtonBar class];
}

- (id) initPlatformObject: (id)platformObject
{	[_attributes setObject: @"24" forKey: @"height"];
	platformObject = [super initPlatformObject: platformObject];
	[platformObject setHasResizeControl: [self boolValueForAttribute:"resizable"]==1 ];
	var buttons=[];

	var peek;
	if(peek=[self stringValueForAttribute:"plusButtonAction"] )
	{	var button=[CPButtonBar plusButton];
		[button setAction: CPSelectorFromString (peek)];
		[buttons addObject: button];
	}
	if(peek=[self stringValueForAttribute:"minusButtonAction"] )
	{	var button=[CPButtonBar minusButton];
		[button setAction: CPSelectorFromString (peek)];
		[buttons addObject: button];
	}
	if([self boolValueForAttribute:"actionsButton"]==1)
	{	var actionButton;
		[buttons addObject:actionButton=[CPButtonBar actionPopupButton] ];
		var i, count = [_content count];
    
		for (i = 0; i < count; i++)
		{	var item = [_content objectAtIndex: i];
			var title = [item localizedStringValueForAttribute: @"title"];
			if (title == nil) title = @"";
			[actionButton addItemWithTitle: title];
			var platformItem = [actionButton lastItem];
			platformItem = [item initPlatformObject: platformItem];	// load additional attributes into the init platform object
			[item setPlatformObject: platformItem];
		}
	}
	[platformObject setButtons: buttons ];
	return platformObject;
}

@end

@implementation CPButtonBar(RennaissanceAdditions)
-(void) setTarget: someTarget
{	[[self buttons] makeObjectsPerformSelector:@selector(setTarget:) withObject: someTarget];
}
- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{	return GSAutoLayoutExpand;
}
@end


@import <AppKit/CPTokenField.j>
@implementation GSMarkupTagTokenField : GSMarkupTagTextField
+ (CPString) tagName
{
  return @"tokenField";
}

+ (Class) platformObjectClass
{
  return [CPTokenField class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	[_attributes setObject: @"28" forKey: @"height"];

	var peek;
	if (peek=[self stringValueForAttribute:"placeholder"] )
  	  [platformObject setPlaceholderString: peek];

	peek=[self stringValueForAttribute:"tokenSeparators"];
	if (!peek) peek=" ";
	[platformObject setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString: peek]];

	return platformObject;
}
@end

@implementation CPTokenField (CPTokenFieldItemsBinding)
- (CPArray)_completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
	if([substring length]) return [[self _autocompleteMenu] contentArray];
	return nil;
}

@end
