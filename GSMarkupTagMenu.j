/* -*-objc-*-
   GSMarkupTagMenu.m

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


@implementation GSMarkupTagMenu: GSMarkupTagObject
+ (CPString) tagName
{
  return @"menu";
}

- (id) allocPlatformObject
{
  var platformObject = nil;
  var type = [_attributes objectForKey: @"type"];


  if (type != nil)
  {
    if ([type isEqualToString: @"font"])
	{
	  platformObject = [[CPFontManager sharedFontManager] fontMenu: YES];  
	} else if( [type isEqualToString: @"main"])
	{ platformObject=[CPApp mainMenu];
	}

    }
  
  if (platformObject == nil)
    {
      platformObject = [CPMenu alloc];
    }

  return platformObject;
}


- (id) initPlatformObject: (id)platformObject
{

  /* title */
  {
    var title = [self localizedStringValueForAttribute: @"title"];

    if ([[_attributes objectForKey: @"type"] isEqualToString: @"font"] )
      {
	/* This is special.  In this case, allocPlatformObject gave us
	 * an instance which is already init-ed!
	 */
	if (title != nil)
	  {
	    [platformObject setTitle: title];
	  }
      }
    else
      {
	/* In all other cases, we must do an -init of some sort now.
	 */
	if (title != nil)
	  {
	    platformObject = [platformObject initWithTitle: title];
	  }
	else
	  {
	    platformObject = [platformObject init];
	  }
      }
  }
  
  
  /* type */
  {
    var type = [_attributes objectForKey: @"type"];
  
    if (type != nil)
      {
	 if ([type isEqualToString: @"windows"])
	  {
	    [CPApp setWindowsMenu: platformObject];
	  }
	else if ([type isEqualToString: @"services"])
	  {
	    [CPApp setServicesMenu: platformObject];
	  }
	else if ([type isEqualToString: @"font"])
	  {
	    /* The menu has already been created as font menu.  */
          }
	/* Other types ignored for compatibility with future
	 * expansions.  */
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
-(id) postInitPlatformObject: platformObject
{	var type = [_attributes objectForKey: @"type"];
	if( type&& [type isEqualToString: @"main"])
		[CPMenu setMenuBarVisible:YES];

  /* Create content.  */
  var count = [_content count];
  
  for (var i = 0; i < count; i++)
    {
      /* We have as content either <menuItem> tags, or <menu> tags.  */
      var tag = [_content objectAtIndex: i];
      var item = [tag platformObject];

      /* If what we decoded really is a CPMenu, not a CPMenuItem,
       * wrap it up into a CPMenuItem.
       */
	if ([item isKindOfClass: [CPMenu class]])
	{
	  var menu = item;
	  item = [[CPMenuItem alloc] initWithTitle: [menu title]
				     action: NULL
				     keyEquivalent: @""];
		[item setSubmenu: menu];

	  [platformObject addItem: item];
	  [platformObject setSubmenu:menu forItem: item ];
	} else if (item != nil  &&  [item isKindOfClass: [CPMenuItem class]])
	 {	[platformObject addItem: item];
	 }
    }
	return platformObject;
}
+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end
