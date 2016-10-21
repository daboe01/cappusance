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
@implementation GSMarkupTagPopUpButtonItem:GSMarkupTagObject
+ (CPString) tagName
{
  return @"popUpButtonItem";
}

/* The enclosing GSMarkupTagPopUpButton will extract the 'title'
 * attribute from us and add an entry with that title to itself.  It
 * will then call setPlatformObject: to set the platform object to be
 * that entry.  It will then manually call initPlatformObject: to have
 * it set the basic attributes.
 *
 * We need to have a _platformObject here, because the target of this
 * object might be set using an outlet.
 */

/* Will never be called.  */
- (id) allocPlatformObject
{
  return nil;
}

- (id) initPlatformObject: (id)platformObject
{
    if(!platformObject)
        return;
  /* title done by the enclosing popupbutton  */

  /* tag */
  {
    var tag = [_attributes objectForKey: @"tag"];
    if (tag !== nil)
    {
       [platformObject setTag:parseInt(tag, 10)];
    }
  }
  
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

  /* keyEquivalent */
  {
    var keyEquivalent = [_attributes objectForKey: @"keyEquivalent"];

    /* Mac OS X barfs on a nil keyEquivalent.  */    
    if (keyEquivalent != nil)
      {
	[platformObject setKeyEquivalent: keyEquivalent];
      }
  }
  
  
  /* target done as an outlet.  */
  
  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end
