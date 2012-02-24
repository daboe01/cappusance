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
@import "GSMarkupTagPopUpButtonItem.j"

@implementation GSMarkupTagPopUpButton: GSMarkupTagControl
+ (CPString) tagName
{
  return @"popUpButton";
}

+ (Class) platformObjectClass
{
  return [CPPopUpButton class];
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
  }

  /* Create content.  */
  {
    var i, count = [_content count];
    
    for (i = 0; i < count; i++)
      {
	var item = [_content objectAtIndex: i];
	var title = [item localizedStringValueForAttribute: @"title"];
	
	if (title == nil)
	  {
	    title = @"";
	  }

	[platformObject addItemWithTitle: title];

	/* Now get the item we have just added ... it's the last one,
	 * and set it as the platform object of the item.  */
	{
	  var platformItem = [platformObject lastItem];

	  /* The following call will cause the item to load all
	   * additional attributes into the init platform object.  */

	  platformItem = [item initPlatformObject: platformItem];
	  [item setPlatformObject: platformItem];
	}
      }
  }
  
  /* pullsDown */
  {
    var pullsDown = [self boolValueForAttribute: @"pullsDown"];
    
    if (pullsDown == 1)
      {
	[platformObject setPullsDown: YES];
      }
    else if (pullsDown == 0)
      {
	[platformObject setPullsDown: NO];
      }
  }

  /* autoenablesItems */
  {
    var autoenablesItems = [self boolValueForAttribute: @"autoenablesItems"];
    if (autoenablesItems == 0)
      {
	[platformObject setAutoenablesItems: NO];
      }
  }

  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end
