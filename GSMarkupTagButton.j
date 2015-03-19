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

@import "GSMarkupTagControl.j"

@implementation GSMarkupTagButton: GSMarkupTagControl;
+ (CPString) tagName
{
  return @"button";
}

+ (Class) platformObjectClass
{
  return [CPButton class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];

  /* title */
  {

   var title = [self localizedStringValueForAttribute: @"title"];
   if (title != nil)
      {
	[platformObject setTitle: title];
      }
    else
      {
	[platformObject setTitle: @""];
      }
  }

  /* font */
  {
    var f = [self fontValueForAttribute: @"font"];
    /* Superclass will set the font; this is just a hack for a special
     * case on Apple Mac OS X.
     */
    if (f == nil)
      {
	/* Unbelievable, isn't it ?  The default font of a button on
	 * Mac OS X is not the right font for buttons.  It's 12 points
	 * instead of 13 points.  Fix it.  */
// <!>	[platformObject setFont: [CPFont systemFontOfSize: 0]];
      }
  }


  /* image */
  {
    var image = [_attributes objectForKey: @"image"];

    if (image != nil)
      {
	[platformObject setImage: [[CPImage alloc] initWithContentsOfFile: [CPString stringWithFormat:@"%@/%@", [[CPBundle mainBundle] resourcePath], image]]];
      }
  }

  /* imagePosition */
  {
    var imagePosition = [_attributes objectForKey: @"imagePosition"];
   
    if (imagePosition != nil  &&  [imagePosition length] > 0)
      {
	
	switch ([imagePosition characterAtIndex: 0])
	  {
	  case 'a':
	    if ([imagePosition isEqualToString: @"above"])
	      {
		[platformObject setImagePosition: CPImageAbove];
	      }
	    break;
	  case 'b':
	    if ([imagePosition isEqualToString: @"below"])
	      {
		[platformObject setImagePosition: CPImageBelow];
	      }
	    break;
	  case 'l':
	    if ([imagePosition isEqualToString: @"left"])
	      {
		[platformObject setImagePosition: CPImageLeft];
	      }
	    break;
	  case 'o':
	    if ([imagePosition isEqualToString: @"overlaps"])
	      {
		[platformObject setImagePosition: CPImageOverlaps];
	      }
	    break;
	  case 'r':
	    if ([imagePosition isEqualToString: @"right"])
	      {
		[platformObject setImagePosition: CPImageRight];
	      }
	    break;
	    /* FIXME/TODO - what about imageOnly ? */
	  case 'i':
	    if ([imagePosition isEqualToString: @"imageOnly"])
	      {
		[platformObject setImagePosition: CPImageOnly];
	      }
	    break;
	  }
      }
  }
  
  /* keyEquivalent */
  {
    var keyEquivalent = [_attributes objectForKey: @"keyEquivalent"];
    
    /* Backward-compatible hack to support obsolete attribute 'key'.
     * It will be removed one year from now, on 4 March 2009.
     */
    if (keyEquivalent == nil)
      {
	keyEquivalent = [_attributes objectForKey: @"key"];
	if (keyEquivalent != nil)
	  {
	    CPLog (@"The 'key' attribute of the <button> tag is obsolete; please replace it with 'keyEquivalent'");
	  }
      }

    if (keyEquivalent != nil)
      {
	[platformObject setKeyEquivalent: keyEquivalent];
      }
  }

  /* keyEquivalentModifierMask */
  {
    var keyEquivalentModifierMask = [_attributes objectForKey: @"keyEquivalentModifierMask"];
    if (keyEquivalentModifierMask != nil)
      {
	var maskValuesDictionary;
	var mask = -1;

	maskValuesDictionary 
	  = [CPDictionary
	      dictionaryWithObjectsAndKeys:
		[CPNumber numberWithInt: 0], @"noKey",
		/* According to the Apple Mac OS X reference, these
		 * are the only three key equivalent modifier masks
		 * recognized for buttons.
		 */
		[CPNumber numberWithInt: CPControlKeyMask], @"controlKey",
	      [CPNumber numberWithInt: CPAlternateKeyMask], @"alternateKey",
	      [CPNumber numberWithInt: CPCommandKeyMask], @"commandKey",
	      /* The following one is not listed in the Apple
	       * documentation for buttons, but it is listed for the
	       * menu items.
	       */
	      [CPNumber numberWithInt: CPShiftKeyMask], @"shiftKey"];

	mask = [self integerMaskValueForAttribute: @"keyEquivalentModifierMask"
		     withMaskValuesDictionary: maskValuesDictionary];
	[platformObject setKeyEquivalentModifierMask: mask];
      }
  }
  
  /* alternateTitle */
  {
    var t = [self localizedStringValueForAttribute: @"alternateTitle"];

    if (t != nil)
      {
	[platformObject setAlternateTitle: t];
      }
  }

  /* alternateImage */
  {
    var image = [_attributes objectForKey: @"alternateImage"];

    if (image != nil)
      {
	[platformObject setAlternateImage: [CPImage imageNamed: image]];
      }
  }

  /* type */
  {
    var type = [_attributes objectForKey: @"type"];
    var needsSettingBorderAndBezel = YES;

    if (type != nil)
      {
	/* We follow here the organization of button types used in
	 * Apple Mac OS X.  The button types are quite well organized
	 * according to their function.  If only the names were
	 * simpler to remember. :-)
	 */
	switch ([type characterAtIndex: 0])
	  {
	  case 'm': 
	    /* This is a standard button (for example, an 'OK' button
	     * at the bottom of a panel).  It highlights when you click,
	     * and unhighlights when the mouse goes up.  The highlighting
	     * is done by the system.
	     */
	    if ([type isEqualToString: @"momentaryPushIn"])
	      {
		[platformObject setButtonType: CPMomentaryPushInButton];
	      }

	    /* This is a standard button, the same as momentaryPushIn,
	     * but it does the highlighting by displaying the
	     * alternateTitle and alternateImage.
	     */
	    if ([type isEqualToString: @"momentaryChange"])
	      {
		[platformObject setButtonType: CPMomentaryChangeButton];
	      }
	    break;
	    
	  case 'p':
	    /* This is a button which you click, and it gets pushed on.
	     * When you click again, it's pushed off back again.  The
	     * 'pushing' is done by the system.
	     */
	    if ([type isEqualToString: @"pushOnPushOff"])
	      {
		[platformObject setButtonType: CPPushOnPushOffButton];
	      }
	    break;

	  case 't':
	    /* This is the same as a pushOnPushOff, but when the button
	     * is 'pushed on', this is shown by displaying the alternateTitle
	     * and alternateImage.
	     */
	    if ([type isEqualToString: @"toggle"])
	      {
		[platformObject setButtonType: CPToggleButton];
	      }
	    break;

	  case 's':
	    /* This type of buttons looks like a check box.  The image
	     * and alternate images are automatically set by the system
	     * to provide this appearance.  This button is a stock
	     * button provided by the system.
	     */
	    if ([type isEqualToString: @"switch"])
	      {
		[platformObject setButtonType: CPSwitchButton];
		needsSettingBorderAndBezel = NO;
	      }
	    break;
	  }
      }
    else
      {
	/* Make sure we use the same default button type on all
	 * platforms.  */
	[platformObject setButtonType: CPMomentaryPushInButton];
      }

    /* On Apple Mac OS X, unless we manually set a border/bezel style,
     * the buttons are not displayed properly (nor with the native
     * default style).  We need to set a general style.
     */
    if (needsSettingBorderAndBezel)
      {
	/* For all text buttons, we use CPRoundedBezelStyle.  This is
	 * very good, but the buttons are too spaced (FIXME ??).
	 */
	if (0&&[_attributes objectForKey: @"image"] == nil)
	  {
	//    [platformObject setBezelStyle: CPRoundedBezelStyle];
	  }
	else
	  {
	    /* The default for buttons having an icon/image is supposed
	     * to be a RegularSquareBezelStyle.
	     */
	    [platformObject setBezelStyle: CPRegularSquareBezelStyle];

	    /* But judging by Apple's own applications, it seems that
	     * the default style for buttons having an icon/image is
	     * in practice not bordered, so maybe the following is
	     * better.
	     */
	    /* [platformObject setBordered: NO]; */
	  }
      }

  }

  /* sound */
  {
    var sound = [_attributes objectForKey: @"sound"];

    if (sound != nil)
      {
	[platformObject setSound: [CPSound soundNamed: sound]];
      }
  }

  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObjects: @"title", @"alternateTitle", nil];
}

@end
