@import <CPTextView/CPTextView.j>


@implementation KVOCPText:CPTextView
- (CPString)objectValue
{
    return [self string];
}
- (void)setObjectValue:(CPString)aString
{	[self setString:aString];
}

- (void) didChangeText
{
    [self _continuouslyReverseSetBinding];
	[super didChangeText];
}
- (void) didChangeText
{
    [self _continuouslyReverseSetBinding];
	[super didChangeText];
}
- (BOOL) resignFirstResponder
{
    [self _reverseSetBinding];
	return [super resignFirstResponder];
}
@end

@implementation GSMarkupTagTextView: GSMarkupTagView
+ (CPString) tagName
{
  return @"textView";
}

+ (Class) platformObjectClass
{
  return [KVOCPText class];
}

- (id) initPlatformObject: (id)platformObject
{
  /* Create the textview.  */
  platformObject = [super initPlatformObject: platformObject];

  /* Set attributes of the textview.  */

  /* eventual text is in the content.  */
  {
    var count = [_content count];

    if (count > 0)
      {
	var s = [_content objectAtIndex: 0];

	if (s != nil  &&  [s isKindOfClass: [CPString class]])
	  {
	    [platformObject setString: s];
	  }

      }
  }
  /* backgroundColor */
  {
    var c = [self colorValueForAttribute: @"backgroundColor"];

    if (c != nil)
      {
	[platformObject setBackgroundColor: c];
      }
  }
  /* editable */
  {
    var editable = [self boolValueForAttribute: @"editable"];

    if (editable == 1)
      {
	[platformObject setEditable: YES];
      }
    else if (editable == 0)
      {
	[platformObject setEditable: NO];
      }
  }

  /* selectable */
  {
    var selectable = [self boolValueForAttribute: @"selectable"];

    if (selectable == 1)
      {
	[platformObject setSelectable: YES];
      }
    else if (selectable == 0)
      {
	[platformObject setSelectable: NO];
      }
  }

  {
    var param;

    /* richText (richtext or textonly?) */
    param = [self boolValueForAttribute: @"richText"];

    if (param == 1)
      {
	[platformObject setRichText: YES];
      }
    else if (param == 0)
      {
	[platformObject setRichText: NO];
      }

    /* usesFontPanel (uses the default font panel?) */
    param =  [self boolValueForAttribute: @"usesFontPanel"];

    if (param == 1)
      {
	[platformObject setUsesFontPanel: YES];
      }
    else if (param == 0)
      {
	[platformObject setUsesFontPanel: NO];
      }

    /* allowsUndo (should use the default undomanager) */
    param = [self boolValueForAttribute: @"allowsUndo"];

    if (param == 1)
      {
	[platformObject setAllowsUndo: YES];
      }
    else if (param == 0)
      {
	[platformObject setAllowsUndo: NO];
      }

    /* usesRuler (can use the ruler?) */
    param = [self boolValueForAttribute: @"usesRuler"];

    if (param == 1)
      {
	[platformObject setUsesRuler: YES];
      }
    else if (param == 0)
      {
	[platformObject setUsesRuler: NO];
      }

    /* importsGraphics (does it accept graphics or only text?) */
    param = [self boolValueForAttribute: @"importGraphics"];

    if (param == 1)
      {
	[platformObject setImportsGraphics: YES];
      }
    else if (param == 0)
      {
	[platformObject setImportsGraphics: NO];
      }
  }

  /* TODO: font (big/medium/small, or bold etc)
   *       alignment (left/right/center/natural) */

  /* Previoulsy, we were replacing here the platformObject with an enclosing
     scrollview, so that size/resizing behaviours etc would be set for the
     scrollview.  Unfortunately, var id ="text" attached to the textView tag
     would then refer to the scrollview ... making it difficult to have
     an outlet refer to the textview.  Code to set up the textview has been
     moved in the scrollview class, so that var id ="xxx" works fine, but you
     manually have to always enclose a textView into a scrollView.
  */

  return platformObject;
}

- (id) postInitPlatformObject: (id)platformObject
{
  return [super postInitPlatformObject: platformObject];
}

@end
