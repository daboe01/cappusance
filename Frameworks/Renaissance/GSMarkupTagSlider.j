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

@implementation GSMarkupTagSlider:GSMarkupTagControl
+ (CPString) tagName
{
  return @"slider";
}

+ (Class) platformObjectClass
{
  return [CPSlider class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];

  var min;
  var max;
  var current;

  min = [_attributes objectForKey: @"min"];
  if (min != nil)
    {
      [platformObject setMinValue: [min doubleValue]];
    }

  max = [_attributes objectForKey: @"max"];
  if (max != nil)
    {
      [platformObject setMaxValue: [max doubleValue]];
    }

  current = [_attributes objectForKey: @"current"];
  if (current != nil)
    {
      [platformObject setDoubleValue: [current doubleValue]];
    }

  /* minimum size is 83x17, like Gorm */
  var height;
  height = [_attributes objectForKey: @"height"];
  if (height == nil)
    {
  [_attributes setObject: @"16" forKey: @"height"];
    }
  var width;
  width = [_attributes objectForKey: @"width"];
  if (width == nil)
    {
  [_attributes setObject: @"83" forKey: @"width"];
    }

  return platformObject;
}
@end
