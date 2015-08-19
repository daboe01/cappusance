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

@implementation GSMarkupTagTextField: GSMarkupTagControl
+ (CPString) tagName
{
  return @"textField";
}

+ (Class) platformObjectClass
{
  return [CPTextField class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];

  /* should be editable and selectable by default.  */

  /* editable */
  {
    var editable = [self boolValueForAttribute: @"editable"];
    
    if (editable == 0)
      {
	[platformObject setEditable: NO];
      }
    else
      {
	[platformObject setEditable: YES];	
      }
  }

  /* selectable */
  {
    var selectable = [self boolValueForAttribute: @"selectable"];
    
    if (selectable == 0)
      {
	[platformObject setSelectable: NO];
      }
    else
      {
	[platformObject setSelectable: YES];
      }
  }
  
  /* allowsEditingTextAttributes  */
  if( [platformObject respondsToSelector:@selector(setAllowsEditingTextAttributes:)])
  {
    var allowsEditingTextAttributes = [self boolValueForAttribute: @"allowsEditingTextAttributes"];

    if (allowsEditingTextAttributes == 1 )
      {
	[platformObject setAllowsEditingTextAttributes: YES];
      }
    else
      {
	[platformObject setAllowsEditingTextAttributes: NO];
      }
  }

  /* importsGraphics  */
  if( [platformObject respondsToSelector:@selector(setImportsGraphics:)])
  {
    var importsGraphics = [self boolValueForAttribute: @"importsGraphics"];

    if (importsGraphics == 1)
      {
	[platformObject setImportsGraphics: YES];
      }
    else
      {
	[platformObject setImportsGraphics: NO];
      }
  }

  /* placeholder */
  {
    var c = [self stringValueForAttribute: @"placeholder"];
    
    if (c != nil)
      {
	[platformObject setPlaceholderString: c];
      }
  }

  /* textColor */
  {
    var c = [self colorValueForAttribute: @"textColor"];
    
    if (c != nil)
      {
	[platformObject setTextColor: c];
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

  /* drawsBackground */
  {
    var drawsBackground = [self boolValueForAttribute: @"drawsBackground"];

    if (drawsBackground == 1)
      {
	[platformObject setDrawsBackground: YES];
      }
    else if (drawsBackground == 0)
      {
	[platformObject setDrawsBackground: NO];
      }
  }

  /* eventual text is in the content.  */
  {
      {
	if (_content != nil)
	  {
	    [platformObject setStringValue: _content];
	  }
      }
  }
	[platformObject setBezeled:YES];

  return platformObject;
}

@end


@implementation GSMarkupTagComboBox: GSMarkupTagTextField
+ (CPString) tagName
{
	return @"comboBox";
}

+ (Class) platformObjectClass
{
	return [CPComboBox class];
}

- (id) initPlatformObject: (id)platformObject
{
	platformObject = [super initPlatformObject: platformObject];
	if([self boolValueForAttribute: @"completes"]===1)
	{	[platformObject setCompletes:YES];
	}

	return platformObject;
}

@end

@implementation GSMarkupTagSearchField: GSMarkupTagTextField
+ (CPString) tagName
{
	return @"searchField";
}

+ (Class) platformObjectClass
{
	return [CPSearchField class];
}

- (id) initPlatformObject: (id)platformObject
{
	platformObject = [super initPlatformObject: platformObject];
  /* autosaveName */
    var autosaveName = [_attributes objectForKey: @"autosaveName"];
    if (autosaveName != nil) [platformObject setRecentsAutosaveName: autosaveName];

	return platformObject;
}
- (id) postInitPlatformObject: (id)platformObject
{
	platformObject = [super postInitPlatformObject: platformObject];
	[platformObject _init];
	return platformObject;
}

@end


@implementation GSMarkupTagSecureTextField: GSMarkupTagTextField
+ (CPString) tagName
{
	return @"secureField";
}

+ (Class) platformObjectClass
{
	return [CPSecureTextField class];
}

@end
