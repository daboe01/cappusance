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
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPWindow.j>


 GSAutoLayoutExpand = 0;
 GSAutoLayoutWeakExpand = 1;
 GSAutoLayoutAlignMin = 2;
 GSAutoLayoutAlignCenter = 3;
 GSAutoLayoutAlignMax = 4;


@implementation CPView (AutoLayoutDefaults)

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  return GSAutoLayoutAlignCenter;
}

- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  return GSAutoLayoutAlignCenter;
}

- (float) autolayoutDefaultHorizontalBorder
{
  return 4;
}

- (float) autolayoutDefaultVerticalBorder
{
  return 4;
}

@end


@implementation CPTextField (AutoLayoutDefaults)

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  if (0&& [self isBezeled]  ||  [self isEditable])
    {
      return GSAutoLayoutExpand;
    }
  
  return GSAutoLayoutAlignCenter;
}
- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  return GSAutoLayoutAlignMin;
}

@end


@implementation CPScrollView (AutoLayoutDefaults)

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  return GSAutoLayoutExpand;
}

- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  return GSAutoLayoutExpand;
}

@end


@implementation CPSplitView (AutoLayoutDefaults)

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  return GSAutoLayoutExpand;
}

- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  return GSAutoLayoutExpand;
}

@end


@implementation CPBox (AutoLayoutDefaults)

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  var contentView = [self contentView];
  var flag;
  flag = [contentView autolayoutDefaultHorizontalAlignment];

  if (flag == GSAutoLayoutExpand  ||  flag == GSAutoLayoutWeakExpand)
    {
      return flag;
    }

  return GSAutoLayoutAlignCenter;
}

- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  var contentView = [self contentView];
  var flag;
  flag = [contentView autolayoutDefaultVerticalAlignment];

  if (flag == GSAutoLayoutExpand  ||  flag == GSAutoLayoutWeakExpand)
    {
      return flag;
    }

  return GSAutoLayoutAlignCenter;
}

@end

/*
 * On Apple Mac OS X, push buttons when drawing leave around them a
 * lot of empty space.  Maybe the idea is that you put them one just
 * near the other one (with the frames technically touching), and the
 * correct empty space between them is implicitly drawn by the blank
 * space left inside its frame by each button ?  If so, it's
 * inconsistent with the rest of the framework, where objects don't
 * have implicit borders and draw to the edges of their frames; it's
 * impossible to control comfortably button borders programmatically,
 * and it's more trouble for us (and for anyone using the framework).
 *
 * Here we adjust the default border to be 0 to account for this
 * problem.  With a border of 0, buttons when laid out get spaced
 * exactly the native spacing used by other applications on the
 * platforms.  (Un)fortunately, not all buttons draw borders in this
 * weird way.  We adjust only for push text buttons.
 */

@implementation CPButton (AutoLayoutDefaults)

- (float) autolayoutDefaultHorizontalBorder
{
  /* Roughly, use 0 for push buttons, and 4 for the other ones.  
   * Empirically determined.  */
  if ([self isBordered] && [self bezelStyle] == CPRoundedBezelStyle)
    return 0;
  else
    return 4;
}

- (float) autolayoutDefaultVerticalBorder
{
  /* Roughly, use 1 for push buttons, and 4 for the other ones.
   * Empirically determined.  */
  if ([self isBordered] && [self bezelStyle] == CPRoundedBezelStyle)
    return 1;
  else
    return 4;
}

@end

@implementation CPView (DisplayAutoLayoutContainers)

- (void) setDisplayAutoLayoutContainers: (BOOL)flag
{
  var subviews = [self subviews];
  var i, count = [subviews count];
  
  for (i = 0; i < count; i++)
    {
      var subview = [subviews objectAtIndex: i];
      [subview setDisplayAutoLayoutContainers: flag];
    }
}

@end

@implementation CPWindow (DisplayAutoLayoutContainers)

- (void) setDisplayAutoLayoutContainers: (BOOL)flag
{
  [[self contentView] setDisplayAutoLayoutContainers: flag];
}

@end
