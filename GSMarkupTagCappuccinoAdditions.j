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
	if([_attributes objectForKey:"style"] == 'Bar')
	{	[platformObject setDisplayedWhenStopped: YES];
		[platformObject setStyle: CPProgressIndicatorBarStyle];
		[_attributes setObject: @"20" forKey: @"height"];
	}
	else
	{	[platformObject setDisplayedWhenStopped:NO];
		[platformObject setStyle:CPProgressIndicatorSpinningStyle];
		[platformObject setIndeterminate:YES];
		[platformObject setControlSize:CPMiniControlSize];
		[_attributes setObject: @"16" forKey: @"height"];
		[_attributes setObject: @"16" forKey: @"width"];
	}
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
	[platformObject setItemPrototype: proto];
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
{	return [CPTokenField class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	[_attributes setObject: @"29" forKey: @"height"];

	peek=[self stringValueForAttribute:"tokenSeparators"];
	if (!peek) peek=" ";
	[platformObject setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString: peek]];

	return platformObject;
}
@end

@implementation GSMarkupTagSwitchButton: GSMarkupTagButton
+ (CPString) tagName
{
  return @"switchButton";
}

+ (Class) platformObjectClass
{	return [CPCheckBox class];
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


@implementation GSMarkupTagDatePicker: GSMarkupTagControl
+ (CPString) tagName
{
  return @"datePicker";
}

+ (Class) platformObjectClass
{	return [CPDatePicker class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];
	[platformObject setLocale: [[CPLocale alloc] initWithLocaleIdentifier:@"de_DE"]];	//<!> fixme
    var styleString = [_attributes objectForKey: @"style"];
	if(styleString === 'textual')
	{   [platformObject setDatePickerStyle: CPTextFieldAndStepperDatePickerStyle];
	    [_attributes setObject: @"120" forKey: @"width"];
	    [_attributes setObject: @"29" forKey: @"height"];
    	    [platformObject setDatePickerElements: CPYearMonthDayDatePickerElementFlag];
	}
	else if(styleString === 'graphical')
        {   [platformObject setDatePickerStyle: CPClockAndCalendarDatePickerStyle];
            [platformObject setDatePickerElements: CPYearMonthDatePickerElementFlag]
	    [_attributes setObject: @"100" forKey: @"width"];
	    [_attributes setObject: @"100" forKey: @"height"];
        }

	return platformObject;
}

- (id) postInitPlatformObject: (id)platformObject
{	platformObject=[super postInitPlatformObject: platformObject];
	[platformObject _init];
	return platformObject;
}

@end


@implementation FSObservableSegmentedControl:CPSegmentedControl
-(void) setSegments:(CPArray) anArray
{   var info=[CPBinder infoForBinding: "segments" forObject: self];
	var tagArray;

	if(info)	// this stuff is to allow row-wise filtered popup-lists in table-views
	{	var options= [info objectForKey: CPOptionsKey];
		var ac=   [info objectForKey: CPObservedObjectKey];
		var mykey=[info objectForKey: CPObservedKeyPathKey];
		var dotIndex = mykey.lastIndexOf("."),
		mykey=[mykey substringFromIndex: dotIndex+1];
		var myvalkey=[options objectForKey: "valueFace"];
		if(myvalkey)
		{	dotIndex = myvalkey.lastIndexOf("."),
			myvalkey=[myvalkey substringFromIndex: dotIndex+1];
		}
		var sourceArray=[ac arrangedObjects];
		someArray=[];
		tagArray=[];

		var  i, l = [sourceArray count];
		for (i = 0; i < l; i++)
		{	var curr_obj= [sourceArray objectAtIndex:i];
			someArray.push([curr_obj valueForKey: mykey]);
			if(myvalkey) tagArray.push([curr_obj valueForKey: myvalkey]);
		}
	}
	var  j, l1 = someArray.length;

    [self setSegmentCount: l1];
	for (j = 0; j < l1; j++)
	{   [self setLabel:someArray[j]  forSegment: j];
		if(tagArray)  [self setTag: tagArray[j] forSegment: j];
	}
    [self setSelectedSegment:0]; // FIXME
}
- (void)setSelected:(BOOL)isSelected forSegment:(unsigned)aSegment
{
	[self willChangeValueForKey:"selectedSegment"];
    [super setSelected:isSelected forSegment:aSegment];
	[self didChangeValueForKey:"selectedSegment"];
}
@end

@implementation GSMarkupTagSegmentedControl: GSMarkupTagControl
+ (CPString) tagName
{
  return @"segmentedControl";
}

+ (Class) platformObjectClass
{	return [FSObservableSegmentedControl class];
}

- (id) initPlatformObject: (id)platformObject
{	[_attributes setObject: @"25" forKey: @"height"];
	platformObject = [super initPlatformObject: platformObject];
	var i, peek, count = [_content count];
    [platformObject setSegmentCount: count];
	for (i = 0; i < count; i++)
	{	var item = [_content objectAtIndex: i];
		var title = [item localizedStringValueForAttribute: @"title"];
		if (title == nil) title = @"";
    	[platformObject setLabel: title forSegment: i];
    	[platformObject setTag: [item intValueForAttribute: @"tag"] forSegment: i];
		if(peek=[self intValueForAttribute:"width"]) [platformObject setWidth: peek forSegment:i];
		if([item boolValueForAttribute:"selected"] == 1) [platformObject setSelected:YES forSegment:i];
	}
	return platformObject;
}


@end
@implementation GSMarkupTagSegmentedControlItem: GSMarkupTagObject
+ (CPString) tagName
{
  return @"segmentedControlItem";
}

@end


@implementation GSMarkupTagWebView: GSMarkupTagView
+ (CPString) tagName
{
  return @"webView";
}

+ (Class) platformObjectClass
{	return [CPWebView class];
}

- (id) initPlatformObject: (id)platformObject
{
	platformObject = [super initPlatformObject: platformObject];

    var count = [_content count];

    if (count > 0)
    {
	    var s = [_content objectAtIndex: 0];

        if (s != nil  &&  [s isKindOfClass: [CPString class]])
        {
	        [platformObject loadHTMLString:s];
        }

    }
	return platformObject;
}
@end
