/* -*-objc-*-
   GSMarkupTagSplitView.m

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: Februrary 2003

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

@import "GSMarkupTagView.j"


@implementation GSMarkupTagSplitView: GSMarkupTagView

+ (CPString) tagName
{
  return @"splitView";
}

+ (Class) platformObjectClass
{
  return [CPSplitView class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [platformObject init];
  [platformObject setDividerStyle:CPSplitViewDividerStyleThin];

  if ([self boolValueForAttribute: @"vertical"] == 0)
      [platformObject setVertical: NO];
  else
      [platformObject setVertical: YES];

  /* Add content.  */
    var count = [_content count];

    for (var i = 0; i < count; i++)
    {
      var view = [_content objectAtIndex:i];
      var v = [view platformObject];

      if (v &&  [v isKindOfClass:[CPView class]])
        [platformObject addArrangedSubview:v];
    }

    return platformObject;
}

/*
- (BOOL) shouldTreatContentAsSubviews
{
  return YES;
}
*/

- (id)postInitPlatformObject:(id)platformObject
{
    platformObject = [super postInitPlatformObject:platformObject];

   /*
    * Make sure subviews are adjusted.  This must be done after the
    * size of the splitview has been set.
    */

    if ([_attributes objectForKey:"autosaveName"])
    {
        [platformObject setAutosaveName:[_attributes objectForKey:"autosaveName"]];
        [platformObject _restoreFromAutosave];
        [platformObject _updateRatios];
        [platformObject adjustSubviews];
    }
    return platformObject;
}

@end

