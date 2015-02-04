/* -*-objc-*-
   GSMarkupTagMenuItem.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2002, November 2002

   var file is part of GNUstep Renaissance

   This library is free software; you can redistribute it and/or
   var it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   var library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   var should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
@import "GSMarkupTagObject.j"

@implementation GSMarkupTagMenuItem: GSMarkupTagObject
+ (CPString) tagName
{
  return @"menuItem";
}

- (id) allocPlatformObject
{
  return [CPMenuItem alloc];
}

- (id) initPlatformObject: (id)platformObject
{
  /* title key action */
  var title = [self localizedStringValueForAttribute: @"title"];
  var keyEquivalent = [_attributes objectForKey: @"keyEquivalent"];
  var action = NULL;
 
  {
    var actionString = [_attributes objectForKey: @"action"];
    if (actionString != nil)
      {
	action = CPSelectorFromString (actionString);
	if (action == NULL)
	  {
	    CPLog (@"Warning: <%@> has non-existing action '%@'.  Ignored.",
		   [[self class] tagName], actionString);
	  }
      }
  }

  /* Backward-compatible hack to support obsolete attribute 'key'.
   * It will be removed one year from now, on 4 March 2009.
   */
  if (keyEquivalent == nil)
    {
      keyEquivalent = [_attributes objectForKey: @"key"];
      if (keyEquivalent != nil)
	{
	  CPLog (@"The 'key' attribute of the <menuItem> tag is obsolete; please replace it with 'keyEquivalent'");
	}
    }

  /* Mac OS X barfs on a nil keyEquivalent.  */
  if (keyEquivalent == nil)
    {
      keyEquivalent = @"";
    }
  
  /* Mac OS X barfs on a nil title.  */
  if (title == nil)
    {
      title = @"";
    }
  
  platformObject = [platformObject initWithTitle: title
				   action: action
				   keyEquivalent: keyEquivalent];
  
  /* image */
  {
    var image = [_attributes objectForKey: @"image"];

    if (image != nil)
      {
	[platformObject setImage: [CPImage imageNamed: image]];
      }
  }

  /* tag */
  {
    var tag = [_attributes objectForKey: @"tag"];
    if (tag != nil)
      {
	[platformObject setTag: [tag intValue]];
      }
  }

  /* enabled */
  {
    var enabled = [self boolValueForAttribute: @"enabled"];
    if (enabled == 1)
      {
	[platformObject setEnabled: YES];
      }
    else if (enabled == 0)
      {
	[platformObject setEnabled: NO];
      }
  }

  /* state */
  {
    var state = [_attributes objectForKey: @"state"];
    if (state != nil)
      {
	if ([state isEqualToString: @"on"])
	  {
	    [platformObject setState: CPOnState];
	  }
	else if ([state isEqualToString: @"off"])
	  {
	    [platformObject setState: CPOffState];
	  }
	else if ([state isEqualToString: @"mixed"])
	  {
	    [platformObject setState: CPMixedState];
	  }
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
		 * recognized for menu items.
		 */
	      [CPNumber numberWithInt: CPControlKeyMask], @"controlKey",
	      [CPNumber numberWithInt: CPAlternateKeyMask], @"alternateKey",
	      [CPNumber numberWithInt: CPCommandKeyMask], @"commandKey",
	      [CPNumber numberWithInt: CPShiftKeyMask], @"shiftKey",
	      nil];

	mask = [self integerMaskValueForAttribute: @"keyEquivalentModifierMask"
		     withMaskValuesDictionary: maskValuesDictionary];
	[platformObject setKeyEquivalentModifierMask: mask];
      }
  }

  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end


@implementation GSMarkupTagMenuSeparator:GSMarkupTagMenuItem
+ (CPString) tagName
{
  return @"menuSeparator";
}

- (id) allocPlatformObject
{
  return [CPMenuItem separatorItem];
}

- (id) initPlatformObject: (id)platformObject
{
  return platformObject;
}

@end