
@import "GSMarkupTagView.j"

@implementation GSMarkupTagProgressIndicator : GSMarkupTagView
+ (CPString) tagName
{
  return @"progressIndicator";
}

+ (Class) platformObjectClass
{
  return [CPProgressIndicator class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [super initPlatformObject: platformObject];

	var min;
	var max;
	var current;

	if([self boolValueForAttribute: @"indeterminate"] ==1) [platformObject setIndeterminate:YES];
	if([self boolValueForAttribute: @"displayWhenStopped"] ==1) [platformObject  setDisplayedWhenStopped:YES];

	min = [_attributes objectForKey: @"min"];
	if (min != nil)
    {	[platformObject setMinValue: [min doubleValue]];
    }

	max = [_attributes objectForKey: @"max"];
	if (max != nil)
    {	[platformObject setMaxValue: [max doubleValue]];
    }

  /* minimum size is 83x17*/
	var height;
	height = [_attributes objectForKey: @"height"];
	if (height == nil)
	{
		[_attributes setObject: @"16" forKey: @"height"];
	}
	var width;
	width = [_attributes objectForKey: @"width"];
	if (width == nil)
    {	[_attributes setObject: @"83" forKey: @"width"];
    }

	return platformObject;
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
@end


@implementation GSMarkupPredicateRowTemplate: GSMarkupTagObject

+ (CPString) tagName
{
  return @"rowTemplate";
}
-(CPString) keyPath
{	return [_attributes objectForKey:"keyPath"];
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
@end

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
	var myRows=[CPMutableArray new];

    var i, count = _content.length;
	for (i = 0 ; i < count; i++)
	{	var v = _content[i];
		if([v isKindOfClass: [GSMarkupPredicateRowTemplate class] ])
		{
		alert([[[v content] objectAtIndex:0] keyPath]);
		}
	}

	return platformObject;
}


@end
