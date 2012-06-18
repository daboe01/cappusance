/* -*-objc-*-


   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: January 2003
   Author of Cappuccino port: Daniel Boehringer (2012)

   This file is part of GNUstep Renaissance

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

@import "GSMarkupTagObject.j"
@implementation GSMarkupTagView: GSMarkupTagObject;

+ (CPString) tagName
{
  return @"view";
}

+ (Class) platformObjectClass
{
  return [CPView class];
}

+ (BOOL) useInstanceOfAttribute
{
  return YES;
}

- (id) initPlatformObject: (id)platformObject
{
  /* Choose a reasonable size to start with.  Starting with a zero
   * size is not a good choice as it can easily cause problems of
   * subviews getting negative sizes etc.  If we have a hardcoded
   * size, it's a good idea to use it from the start; if so, we'll
   * also skip the -sizeToFitContent later.
   */
  var frame = CPMakeRect (0, 0, 100, 100);
  var width;
  var height;

  width = [_attributes objectForKey: @"width"];
  if (width != nil)
    {
      var w = [width floatValue];
      if (w > 0)
	{
	  frame.size.width = w;
	}
    }
  
  height = [_attributes objectForKey: @"height"];
  if (height != nil)
    {
      var h = [height floatValue];
      if (h > 0)
	{
	  frame.size.height = h;
	}
    }

  platformObject = [platformObject initWithFrame: frame];

  /* nextKeyView, previousKeyView are outlets :-), done
   * automatically.  */

  return platformObject;
}

/* This is done at init time, but should be done *after* all other
 * initialization - so it is in a separate method which subclasses
 * can/must call at the end of their initPlatformObject: method.  */
- (id) postInitPlatformObject: (id)platformObject
{
  /* If no width or no height is specified, we need to use
   * -sizeToFitContent to choose a good size.
   */
  if (([_attributes objectForKey: @"width"] == nil)
      || ([_attributes objectForKey: @"height"] == nil))
    {
      [platformObject sizeToFitContent];
    }

  /* Now set the hardcoded frame if any.  */
  {
    var frame = [platformObject frame];
    var x, y, width, height;
    var needToSetFrame = NO;
    
    x = [_attributes objectForKey: @"x"];
    if (x != nil)
      {
	frame.origin.x = [x floatValue];
	needToSetFrame = YES;
      }

    y = [_attributes objectForKey: @"y"];
    if (y != nil)
      {
	frame.origin.y = [y floatValue];
	needToSetFrame = YES;
      }

    width = [_attributes objectForKey: @"width"];
    if (width != nil)
      {
	var w = [width floatValue];
	if (w > 0)
	  {
	    frame.size.width = w;
	    needToSetFrame = YES;
	  }
      }

    height = [_attributes objectForKey: @"height"];
    if (height != nil)
      {
	var h = [height floatValue];
	if (h > 0)
	  {
	    frame.size.height = h;
	    needToSetFrame = YES;
	  }
      }
    if (needToSetFrame)
      {
	[platformObject setFrame: frame];
      }
  }

  /* We don't normally use autoresizing masks, except in special
   * cases: mostly stuff contained directly inside CPBox objects.  In
   * that case, any changes in the size of the CPBox will propagate to
   * the object inside it via its autoresizing mask.
   *
   * So we want to convert the autolayout flags of the view into a
   * corresponding autoresizing mask so that it all works as expected
   * when used inside a CPBox - ie, if you var halign ="center" into an
   * CPBox that is itself set to expand, then when the CPBox expands,
   * the view inside is centered.
   *
   * Please note that if we are the window's content view, this could
   * be a problem because on Apple Mac OS X the autoresizing mask gets
   * used (in the vertical direction) and might cause the view to
   * overwrite the window's titlebar (tested with 10.4)!  For that
   * reason, in GSMarkupTagWindow we always set the autoresizing mask
   * of a window's content view to CPViewWidthSizable |
   * CPViewHeightSizable.
   */
  {
    var autoresizingMask = 0;

    {
      /* Read the halign from the tag attributes, and if nothing is
       * found, from the default for that view.  */
      var autoLayoutHorizontalAlignment = 0;
      autoLayoutHorizontalAlignment = [self gsAutoLayoutHAlignment];
      if (autoLayoutHorizontalAlignment == 255)
	{
	  autoLayoutHorizontalAlignment = [platformObject 
					    autolayoutDefaultHorizontalAlignment];
	}
      
      switch (autoLayoutHorizontalAlignment)
	{
	case GSAutoLayoutExpand: 
	case GSAutoLayoutWeakExpand: 
	  autoresizingMask |= CPViewWidthSizable; 
	  break;
	case GSAutoLayoutAlignMin:
	  autoresizingMask |= CPViewMaxXMargin;
	  break;
	case GSAutoLayoutAlignCenter:
	  autoresizingMask |= CPViewMaxXMargin | CPViewMinXMargin;
	  break;
	case GSAutoLayoutAlignMax:
	  autoresizingMask |= CPViewMinXMargin;
	  break;
	}
    }

    {
      /* Read the valign from the tag attributes, and if nothing is
       * found, from the default for that view.  */
      var autoLayoutVerticalAlignment = 0;

      autoLayoutVerticalAlignment = [self gsAutoLayoutVAlignment];
      if (autoLayoutVerticalAlignment == 255)
	{
	  autoLayoutVerticalAlignment = [platformObject 
					  autolayoutDefaultVerticalAlignment];
	}
      
      switch (autoLayoutVerticalAlignment)
	{
	case GSAutoLayoutExpand: 
	case GSAutoLayoutWeakExpand: 
	  autoresizingMask |= CPViewHeightSizable; 
	  break;
	case GSAutoLayoutAlignMin:
	  autoresizingMask |= CPViewMaxYMargin;
	  break;
	case GSAutoLayoutAlignCenter:
	  autoresizingMask |= CPViewMaxYMargin | CPViewMinYMargin;
	  break;
	case GSAutoLayoutAlignMax:
	  autoresizingMask |= CPViewMinYMargin;
	  break;
	}
    }

    [platformObject setAutoresizingMask: autoresizingMask];
  }

  /* You can set autoresizing masks if you're trying to build views in the
   * old hardcoded size style.  Else, it's pretty useless.
   *
   * Subclasses have each one their own default autoresizing mask.  We
   * only modify the existing one if a different one is specified in
   * the .gsmarkup file.  The format for specifying them is as in
   * autoresizingMask="hw" for CPViewHeightSizable |
   * CPViewWidthSizable, var autoresizingMask ="" for nothing,
   * autoresizingMask="xXhy" for CPViewMinXMargin | CPViewMaxXMargin |
   * CPViewHeightSizable | CPViewMinYMargin.
   */
  {
    var autoresizingMaskString = [_attributes objectForKey: 
						      @"autoresizingMask"];

    if (autoresizingMaskString != nil)
      {
	var i, count = [autoresizingMaskString length];
	var newAutoresizingMask = 0;
	
	for (i = 0; i < count; i++)
	  {
	    var c = [autoresizingMaskString characterAtIndex: i];

	    switch (c)
	      {
	      case 'h':
		newAutoresizingMask |= CPViewHeightSizable;
		break;
	      case 'w':
		newAutoresizingMask |= CPViewWidthSizable;
		break;
	      case 'x':
		newAutoresizingMask |= CPViewMinXMargin;
		break;
	      case 'X':
		newAutoresizingMask |= CPViewMaxXMargin;
		break;
	      case 'y':
		newAutoresizingMask |= CPViewMinYMargin;
		break;
	      case 'Y':
		newAutoresizingMask |= CPViewMaxYMargin;
		break;
	      default:
		break;
	      }
	  }
      if (newAutoresizingMask != [platformObject autoresizingMask])
        {
          [platformObject setAutoresizingMask: newAutoresizingMask];
        }
      }
  }
  
  {
    /* This attribute is only there for people wanting to use the old
     * legacy OpenStep autoresizing system.  We ignore it otherwise.
     */
    var autoresizesSubviews = [self boolValueForAttribute: @"autoresizesSubviews"];

    if (autoresizesSubviews == 0)
      {
	[platformObject setAutoresizesSubviews: NO];
      }
    else if (autoresizesSubviews == 1)
      {
	[platformObject setAutoresizesSubviews: YES];
      }
  }

  if ([self boolValueForAttribute: @"hidden"] == 1)
    {
      [platformObject setHidden: YES];
    }

  {
    var toolTip = [self localizedStringValueForAttribute: @"toolTip"];
    if (toolTip != nil)
      {
	[platformObject setToolTip: toolTip];
      }
  }

  if (([self class] == [GSMarkupTagView class]) 
      || [self shouldTreatContentAsSubviews])
    {
      /* Extract the contents of the tag.  Contents are subviews that
       * get added to us.  This should only be used in special cases
       * or when the (legacy) OpenStep autoresizing system is used
       * (also, splitviews use it).  In all other cases, vbox and hbox
       * and similar autoresizing containers should be used.
       */
      var i, count = [_content count];
      
      /* Go in the order found in the XML file, so that the list of
       * views in the XML file goes from the ones below to the
       * ones above.
       * Ie, in
       *  <var id ="1">
       *    <var id ="2" />
       *    <var id ="3" />
       *  </view>
       * view 3 appears over view 2.
       */
      for (i = 0; i < count; i++)
	{
	  var v = [_content objectAtIndex: i];
	  var view = [v platformObject];
	  
	  if (view != nil  &&  [view isKindOfClass: [CPView class]])
	    {
	      [platformObject addSubview: view];
	    }
	}
    }

  return platformObject;
}

/* This is ignored unless it returns YES, in which cases it forces
 * loading all content tags as subviews.
 */
- (BOOL) shouldTreatContentAsSubviews
{
  return NO;
}

- (int) gsAutoLayoutHAlignment
{
  var halign;

  if ([self boolValueForAttribute: @"hexpand"] == 1)
    {
      return GSAutoLayoutExpand;
    }

  halign = [_attributes objectForKey: @"halign"];

  if (halign != nil)
    {
      if ([halign isEqualToString: @"expand"])
	{
	  return GSAutoLayoutExpand;
	}
      else if ([halign isEqualToString: @"wexpand"])
	{
	  return GSAutoLayoutWeakExpand;
	}
      else if ([halign isEqualToString: @"min"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([halign isEqualToString: @"left"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([halign isEqualToString: @"center"])
	{
	  return GSAutoLayoutAlignCenter;
	}
      else if ([halign isEqualToString: @"max"])
	{
	  return GSAutoLayoutAlignMax;
	}
      else if ([halign isEqualToString: @"right"])
	{
	  return GSAutoLayoutAlignMax;
	}
    }

  return 255;
}

- (int) gsAutoLayoutVAlignment
{
  var valign;

  if ([self boolValueForAttribute: @"vexpand"] == 1)
    {
      return GSAutoLayoutExpand;
    }

  valign = [_attributes objectForKey: @"valign"];

  if (valign != nil)
    {
      if ([valign isEqualToString: @"expand"])
	{
	  return GSAutoLayoutExpand;
	}
      else if ([valign isEqualToString: @"wexpand"])
	{
	  return GSAutoLayoutWeakExpand;
	}
      else if ([valign isEqualToString: @"min"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([valign isEqualToString: @"bottom"])
	{
	  return GSAutoLayoutAlignMin;
	}
      else if ([valign isEqualToString: @"center"])
	{
	  return GSAutoLayoutAlignCenter;
	}
      else if ([valign isEqualToString: @"max"])
	{
	  return GSAutoLayoutAlignMax;
	}
      else if ([valign isEqualToString: @"top"])
	{
	  return GSAutoLayoutAlignMax;
	}
    }

  return 255;
}

@end
