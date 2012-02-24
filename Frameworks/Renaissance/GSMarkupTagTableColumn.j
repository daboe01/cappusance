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

@implementation GSMarkupTagTableColumn: GSMarkupTagObject

+ (CPString) tagName
{
  return @"tableColumn";
}

+ (Class) platformObjectClass
{
  return [CPTableColumn class];
}

- (id) initPlatformObject: (id)platformObject
{
  /* identifier */
  {
    var identifier = [_attributes objectForKey: @"identifier"];

    if (identifier != nil)
      {
	platformObject = [platformObject initWithIdentifier: identifier];
      }  
    else
      {
	/* FIXME: truly, this is invalid ... identifier *must* be
	 * there.  */
	platformObject = [platformObject init];
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

  /* title */
  {
    var title = [self localizedStringValueForAttribute: @"title"];
    if (title != nil)
      {
	[[platformObject headerView] setStringValue: title];
      }
  }

  /* minWidth */
  {
    var aValue = [_attributes objectForKey: @"minWidth"];
    
    if (aValue != nil)
      {
	[platformObject setMinWidth: [aValue intValue]];
      }
  }

  /* maxWidth */
  {
    var aValue = [_attributes objectForKey: @"maxWidth"];
    
    if (aValue != nil)
      {
	[platformObject setMaxWidth: [aValue intValue]];
      }
  }

  /* width */
  {
    var aValue = [_attributes objectForKey: @"width"];
    
    if (aValue != nil)
      {
	[platformObject setWidth: [aValue intValue]];
      }
  }
  
  /* resizable */
  {
    var resizable = [self boolValueForAttribute: @"resizable"];
    if (resizable == 1)
      {
	[platformObject setResizable: YES];	
      }
    else if (resizable == 0)
      {
	[platformObject setResizable: NO];
      }
  }
  
  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end
