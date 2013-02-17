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
@import "GSMarkupTagView.j"

@implementation GSMarkupTagControl:  GSMarkupTagView;

+ (CPString) tagName
{
  return @"control";
}

+ (Class) platformObjectClass
{
  return [CPControl class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [platformObject init];
  
  /* action */
  {
    var action = [_attributes objectForKey: @"action"];
  
    if (action != nil)    
      {
	var selector = CPSelectorFromString (action);
	if (selector == NULL)
	  {
	    CPLog (@"Warning: <%@> has non-existing action '%@'.  Ignored.",
		   [[self class] tagName], action);
	  }
	else
	  {
	    [platformObject setAction: selector];
	  }
      }
  }

  /* continuous */
  {
    var continuous = [self boolValueForAttribute: @"continuous"];
    
    if (continuous == 1)
      {
	[platformObject setContinuous: YES];
      }
    else if (continuous == 0)
      {
	[platformObject setContinuous: NO];
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

  /* tag */
  {
    var tag = [_attributes objectForKey: @"tag"];
    if (tag != nil)
      {
	[platformObject setTag: [tag intValue]];
      }
  }

  /* sendActionOn */
  {
    var sendActionOn = [_attributes objectForKey: @"sendActionOn"];
    if (sendActionOn != nil)
      {
	var maskValuesDictionary;
	var mask = -1;

	maskValuesDictionary 
	  = [CPDictionary
	      dictionaryWithObjectsAndKeys:
		[CPNumber numberWithInt: CPLeftMouseDownMask], @"leftMouseDown",
	      [CPNumber numberWithInt: CPLeftMouseUpMask], @"leftMouseUp",
	      [CPNumber numberWithInt: CPRightMouseDownMask], @"rightMouseDown",
	      [CPNumber numberWithInt: CPRightMouseUpMask], @"rightMouseUp",
	      [CPNumber numberWithInt: CPMouseMovedMask], @"mouseMoved",
	      [CPNumber numberWithInt: CPLeftMouseDraggedMask], @"leftMouseDragged",
	      [CPNumber numberWithInt: CPRightMouseDraggedMask], @"rightMouseDragged",
	      [CPNumber numberWithInt: CPMouseEnteredMask], @"mouseEntered",
	      [CPNumber numberWithInt: CPMouseExitedMask], @"mouseExited",
	      [CPNumber numberWithInt: CPKeyDownMask], @"keyDown",
	      [CPNumber numberWithInt: CPKeyUpMask], @"keyUp",
	      [CPNumber numberWithInt: CPFlagsChangedMask], @"flagsChanged",
	      [CPNumber numberWithInt: CPAppKitDefinedMask], @"appKeyDefined",
	      [CPNumber numberWithInt: CPSystemDefinedMask], @"systemDefined",
	      [CPNumber numberWithInt: CPApplicationDefinedMask], @"applicationDefined",
	      [CPNumber numberWithInt: CPPeriodicMask], @"periodic",
	      [CPNumber numberWithInt: CPCursorUpdateMask], @"cursorUpdate",
	      [CPNumber numberWithInt: CPScrollWheelMask], @"scrollWheel",
	      [CPNumber numberWithInt: CPOtherMouseDownMask], @"otherMouseDown",
	      [CPNumber numberWithInt: CPOtherMouseUpMask], @"otherMouseUp",
	      [CPNumber numberWithInt: CPOtherMouseDraggedMask], @"otherMouseDragged",
	      [CPNumber numberWithInt: CPAnyEventMask], @"anyEvent"];

	mask = [self integerMaskValueForAttribute: @"sendActionOn"
		     withMaskValuesDictionary: maskValuesDictionary];
	[platformObject sendActionOn: mask];
      }
  }

  /* textAlignment */
  {
    var alignment = [_attributes objectForKey: @"textAlignment"];

    /* Backwards-compatible check introduced on 27 Feb 2008, will be
     * removed on 27 Feb 2009.
     */
    if (alignment == nil)
      {
	/* Check for the old name "align"  */
	alignment = [_attributes objectForKey: @"align"];

	if (alignment != nil)
	  {
	    CPLog (@"The 'align' attribute has been renamed to 'textAlignment'.  Please update your gsmarkup files");
	  }
      }
    
    if (alignment != nil)
      {
	if ([alignment isEqualToString: @"left"])
	  {
	    [platformObject setAlignment: CPLeftTextAlignment];
	  }
	else if ([alignment isEqualToString: @"right"])
	  {
	    [platformObject setAlignment: CPRightTextAlignment];
	  }
	else if ([alignment isEqualToString: @"center"])    
	  {
	    [platformObject setAlignment: CPCenterTextAlignment];
	  }
      }
  }

  /* font */
  {
    var f = [self fontValueForAttribute: @"font"];
    if (f != nil)
      {
	[platformObject setFont: f];
      }
  }

  return platformObject;
}

@end
