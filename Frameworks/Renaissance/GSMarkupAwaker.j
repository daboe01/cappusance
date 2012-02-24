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

@import <Foundation/CPObject.j>

@implementation GSMarkupAwaker:CPObject

- (id) init
{
  _objects = [CPMutableSet new];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) registerObject: (id)object
{
  [_objects addObject: object];
}

- (void) deregisterObject: (id)object
{
  [_objects removeObject: object];
}

- (void) awakeObjects
{
  var e = [_objects objectEnumerator];
  var object;

  while ((object = [e nextObject]) != nil)
    {
      if ([object respondsToSelector: @selector(awakeFromGSMarkup)])
      {
	[object awakeFromGSMarkup];
      }
    }
}

@end

