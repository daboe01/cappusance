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
@import <AppKit/CPView.j>
@import <AppKit/CPControl.j>
@import <AppKit/CPBox.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPColorWell.j>

@implementation CPView (sizeToContent)

- (void) sizeToFitContent
{
  /* In the general case of a general view, this is a no-op.  We have
   * no idea how to fit the size to the content; we trust that whoever
   * set up the view set up the width and height to be the right ones
   * for the content.  This has the additional benefit that
   * -minimuSizeForContent will return the current size of the view as
   * the minimum; ie, unless we know otherwise, we assume that the
   * view has been sized to display its content properly and we don't
   * want to shrink it.
   */
}

- (CPSize) minimumSizeForContent
{
  var oldFrame;
  var minimumSize;

  /* Save the oldFrame.  */
  oldFrame = [self frame];
  
  /* Resize the view to fit the contents ... this is the only
   * way available in the AppKit to get the minimum size.  */
  [self sizeToFitContent];

  /* Get the minimum size by reading the frame.  */
  minimumSize = [self frame].size;
  
  /* Restore the original frame.  */
  [self setFrame: oldFrame];
  
  return minimumSize;
}

@end

@implementation CPControl (sizeToContent)

- (void) sizeToFitContent
{
  if([self respondsToSelector:@selector(sizeToFit) ]) [self sizeToFit];
}

@end

/* CPBox comments - make sure you realize that CPBox -sizeToFit calls
 * the contentView's -sizeToFit method.  If you want the CPBox
  contentview to have a hardcoded frame which is not the minimum
 * size, you need to embed it in a [hv]box before putting it in
 * the CPBox, to make sure this hardcoded frame overrides the minimum
 * size.
 */
@implementation CPBox (sizeToContent)

- (void) sizeToFitContent
{
  [self sizeToFit];
}

@end

/* CPSplitView's sizeToContent makes the splitview just big enough
 * to display its subviews, plus the dividers.  
 *
 * NB: (not really relevant any longer, but for future memories of
 * past problems) the default implementation of setting a CPZeroSize
  would not work because resizing a splitview resizes all subviews,
 * and resizing a splitview to a zero size, at least on GNUstep,
 * resizes all subviews to have zero size, losing all size
 * relationships between them ... it's an unrecoverable operation on
 * GNUstep.
 */
@implementation CPSplitView (sizeToContent)
- (void) sizeToFitContent
{
  var newSize = CPMakeSize(0,0);
  var subviews = [self subviews];
  var i, count = [subviews count];
  var dividerThickness = [self dividerThickness];

  if (count == 0)
    {
      [self setFrameSize: newSize];
      return;
    }

  if ([self isVertical])
    {
      var subview = [subviews objectAtIndex: 0];
      var subviewRect = [subview frame];

      newSize.height = subviewRect.size.height;

      for (i = 0; i < count; i++)
	{
	  subview = [subviews objectAtIndex: i];
	  subviewRect = [subview frame];
	  
	  newSize.width += subviewRect.size.width;
	}
      
      newSize.width += dividerThickness * (count - 1);
    }
  else
    {
      var subview = [subviews objectAtIndex: 0];
      var subviewRect = [subview frame];

      newSize.width = subviewRect.size.width;

      for (i = 0; i < count; i++)
	{
	  subview = [subviews objectAtIndex: i];
	  subviewRect = [subview frame];
	  
	  newSize.height += subviewRect.size.height;
	}
      
      newSize.height += dividerThickness * (count - 1);
    }
  
  [self setFrameSize: newSize];
}
@end

@implementation CPTextField (sizeToContent)

/* We want text fields to get a reasonable size when empty.  */
- (void) sizeToFitContent
{
  var stringValue = [self stringValue];
  
  if (stringValue == nil  ||  [stringValue length] == 0)
    {
      [self setStringValue: @"Nicola"];
      [self sizeToFit];
      [self setStringValue: @""];
    }
  else
    {
      [self sizeToFit];
    }
}

@end


/* CPImageView does not support sizeToFit on Apple!  The following
 * hack only works after the image has just been set.  */
@implementation CPImageView (sizeToContent)
- (void) sizeToFitContent
{
  [self setFrameSize: [[self image] size]];
}
@end

/* CPColorWell does not have a working sizeToFit; let's just implement
 * it to use a minimum size of 52x30, which is roughly Gorm's default
 * color well size.  */
@implementation CPColorWell (sizeToContent)

- (void) sizeToFitContent
{
  [self setFrameSize: [self minimumSizeForContent]];
}

- (CPSize) minimumSizeForContent
{
  return CPMakeSize (52, 30);
}

@end
