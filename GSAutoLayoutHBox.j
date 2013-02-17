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

@import "GSAutoLayoutManager.j"
@import "GSAutoLayoutStandardManager.j"
@import "GSAutoLayoutProportionalManager.j"


@implementation GSAutoLayoutHBoxViewInfo: CPObject
{  var _view;

  /* The view minimum size.  When the view is first added, its size
   * is automatically used as the view minimum size.  You can change
   * the minimum size later on programmatically by specifying a new
   * minimum size, or by asking the autolayout view to update
   * itself, in which case the autolayout view examines all views,
   * and if any view has a size which is different from the size it
   * is supposed to have, the new size is used as the view's minimum
   * size.  */
  var _minimumSize;

  /* Expand/Alignment in the horizontal direction.  */
  var _hAlignment;

  /* Expands/Alignment in the vertical direction.  */
  var _vAlignment;
    
  /* A horizontal border.  */
  var _hBorder;
  
  /* A vertical border.  */
  var _vBorder;

  /* For views that should look bigger (or smaller!) in proportional
   * autolayout managers.  */
  var _proportion;

  /* The autolayout _vManager id of this column.  */
  var _column;
}


- (id) initWithView: (CPView)aView
	     column: (id)aColumn
{
  _view = aView;
  _column = aColumn;
  return self;
}

@end

@implementation GSAutoLayoutHBox: CPView
{
  /* The info on the views.  */
  NSMutableArray _viewInfo;

  /* YES if there is any view with GSAutoLayoutExpand alignment in the
     horizontal direction, NO otherwise.  */
  BOOL _hExpand;

  /* YES if there is any view with GSAutoLayoutWeakExpand alignment in the
     horizontal direction, NO otherwise.  */
  BOOL _hWeakExpand;

  /* Idem in vertical.  */
  BOOL _vExpand;
  BOOL _vWeakExpand;

  /* The GSAutoLayoutManagers.  */
  GSAutoLayoutManager _hManager;
  GSAutoLayoutManager _vManager;
  
  /* The id identifying our line with the horizontal
     GSAutoLayoutManager.  */
  id _line;

  /* YES if we display red lines to represent the autolayout (for 
   * debugging/graphical editing purposes); NO if not (the default,
   * we are invisible by default).
   */
  BOOL _displayAutoLayoutContainers;
}

- (id) init
{
  var manager;

  self = [super initWithFrame: CPZeroRect];
  /* Turn off traditional OpenStep subview autoresizing.  */
  [self setAutoresizesSubviews: NO];
  /* By default we are resizable in width and height ... in case we
   * are placed top-level in the window: we want to receive all
   * resizing of the window around us.  */
  [self setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];

  _viewInfo = [CPMutableArray new];

  /* The horizontal layout manager is by default a standard one,
   * but could be changed.  */
  manager = [GSAutoLayoutStandardManager new];
  [self setAutoLayoutManager: manager];
  /* The vertical layout manager is always a standard layout manager
   * and can't be changed (pointless to change it anyway!) */
  _vManager = [GSAutoLayoutStandardManager new];
  
  [[CPNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(autoLayoutManagerChangedVLayout:)
    name: GSAutoLayoutManagerChangedLayoutNotification
    object: _vManager];

  return self;
}

- (void) setBoxType: (GSAutoLayoutBoxType)type
{
  if (type != [self boxType])
    {
      var manager = nil;

      if (type == GSAutoLayoutProportionalBox)
	{
	  manager = [GSAutoLayoutProportionalManager new];
	}
      else
	{
	  manager = [GSAutoLayoutStandardManager new];
	}

      [self setAutoLayoutManager: manager];
      }
}

- (GSAutoLayoutBoxType) boxType
{
  if ([_hManager isKindOfClass: [GSAutoLayoutProportionalManager class]])
    {
      return GSAutoLayoutProportionalBox;
    }
  else
    {
      return GSAutoLayoutStandardBox;
    }
}

- (void) setAutoLayoutManager: (GSAutoLayoutManager)aLayoutManager
{
  /* NB: this method currently only works if you call it when
   * there are no views in the hbox.  TODO: Extend it.
   */
  _hManager = aLayoutManager;

  _line = [_hManager addLine];

  
  [[CPNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(autoLayoutManagerChangedHLayout:)
    name: GSAutoLayoutManagerChangedLayoutNotification
    object: _hManager];
}

- (GSAutoLayoutManager)autoLayoutManager
{
  return _hManager;
}

/* Private method to retrieve the info for a view.  */
- (GSAutoLayoutHBoxViewInfo) infoForView: (CPView)aView
{
  var i, count = [_viewInfo count];

  for (i = 0; i < count; i++)
    {
      var info = [_viewInfo objectAtIndex: i];

      if (info._view == aView)
	{
	  return info;
	}
    }
  return nil;
}

/* Private methods to push layout info to layout managers.  */
- (void) pushToHManagerInfoForViewAtIndex: (int)i
{
  var info = [_viewInfo objectAtIndex: i];

  [_hManager setMinimumLength: (info._minimumSize).width
	     alignment: info._hAlignment
	     minBorder: info._hBorder
	     maxBorder: info._hBorder
	     span: 1
	     ofSegmentAtIndex: i
	     inLine: _line];

  if (info._proportion != 1)
    {
      [_hManager setMinimumLength: 0
		 alwaysExpands: NO
		 neverExpands: NO
		 proportion: info._proportion
		 ofLinePartAtIndex: i];
    }
  else
    {
      [_hManager removeInformationOnLinePartAtIndex: i];
    }

  [_hManager updateLayout];
}

- (void) pushToVManagerInfoForViewAtIndex: (int)i
{
  var info = [_viewInfo objectAtIndex: i];

  [_vManager setMinimumLength: (info._minimumSize).height
	     alignment: info._vAlignment
	     minBorder: info._vBorder
	     maxBorder: info._vBorder
	     span: 1
	     ofSegmentAtIndex: 0
	     inLine: info._column];

  [_vManager updateLayout];
}

- (void) addView: (CPView)aView
{
  var count = [_viewInfo count];
  var info;	// GSAutoLayoutHBoxViewInfo
  var column = [_vManager addLine];

  info = [[GSAutoLayoutHBoxViewInfo alloc] initWithView: aView  column: column];  
  info._minimumSize = [aView frame].size;
  info._hAlignment = [aView autolayoutDefaultHorizontalAlignment];
  info._vAlignment = [aView autolayoutDefaultVerticalAlignment];
  info._hBorder = [aView autolayoutDefaultHorizontalBorder];
  info._vBorder = [aView autolayoutDefaultVerticalBorder];
  info._proportion = 1;

  if (info._hAlignment == GSAutoLayoutExpand)
    {
      _hExpand = YES;
    }
  if (info._hAlignment == GSAutoLayoutWeakExpand)
    {
      _hWeakExpand = YES;
    }

  if (info._vAlignment == GSAutoLayoutExpand)
    {
      _vExpand = YES;
    }
  if (info._vAlignment == GSAutoLayoutWeakExpand)
    {
      _vWeakExpand = YES;
    }

  [_viewInfo addObject: info];
  [self addSubview: aView];
  
  /* First, vertical layout.  */
  [_vManager insertNewSegmentAtIndex: 0
	     inLine: column];
  
  [self pushToVManagerInfoForViewAtIndex: count];

  /* And then, horizontal layout.  */
  [_hManager insertNewSegmentAtIndex: count
	     inLine: _line];

  [self pushToHManagerInfoForViewAtIndex: count];
}

- (void) removeView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];

  [_vManager removeSegmentAtIndex: 0
	     inLine: info._column];
  [_vManager removeLine: info._column];

  [_hManager removeInformationOnLinePartAtIndex: index];

  [_hManager removeSegmentAtIndex: index
	     inLine: _line];

  [_viewInfo removeObject: info];

  /* Recompute the _vExpand, _hExpand, _vWeakExpand and _hWeakExpand
   * flags.  */
  {
    var i, count = [_viewInfo count];

    _vExpand = NO;
    _vWeakExpand = NO;
    _hExpand = NO;
    _hWeakExpand = NO;
    
    for (i = 0; i < count; i++)
      {
	info = [_viewInfo objectAtIndex: i];
	
	if (info._vAlignment == GSAutoLayoutExpand)
	  {
	    _vExpand = YES;
	  }
	if (info._vAlignment == GSAutoLayoutWeakExpand)
	  {
	    _vWeakExpand = YES;
	  }
	if (info._hAlignment == GSAutoLayoutExpand)
	  {
	    _hExpand = YES;
	  }
	if (info._hAlignment == GSAutoLayoutWeakExpand)
	  {
	    _hWeakExpand = YES;
	  }
      } 
  }
  
  /* Remove the view from our subviews.  */
  [aView removeFromSuperview];

  /* Update the layout.  */
  [_vManager updateLayout];
  [_hManager updateLayout];
}

- (void) autoLayoutManagerChangedVLayout: (CPNotification)notification
{
  var newHeight;
  var i, count;

  if ([notification object] != _vManager)
    {
      return;
    }

  newHeight = [_vManager lineLength];

  [super setFrameSize: CPMakeSize (([self frame]).size.width, newHeight)];

  count = [_viewInfo count];

  for (i = 0; i < count; i++)
    {
      var s;
      var info;
      var newFrame;

      info = [_viewInfo objectAtIndex: i];

      s = [_vManager layoutOfSegmentAtIndex: 0  inLine: info._column];

      newFrame = [info._view frame];
      newFrame.origin.y = s.position;
      newFrame.size.height = s.length;

      [info._view setFrame: newFrame];
    }
}


- (void) autoLayoutManagerChangedHLayout: (CPNotification)notification
{
  var newWidth;
  var i, count;

  if ([notification object] != _hManager)
    {
      return;
    }
  
  newWidth = [_hManager lineLength];

  [super setFrameSize: CPMakeSize (newWidth, ([self frame].size).height)];

  count = [_viewInfo count];

  for (i = 0; i < count; i++)
    {
      var s;
      var info;
      var newFrame;

      info = [_viewInfo objectAtIndex: i];

      s = [_hManager layoutOfSegmentAtIndex: i  inLine: _line];

      newFrame = [info._view frame];
      newFrame.origin.x = s.position;
      newFrame.size.width = s.length;

      [info._view setFrame: newFrame];
    }
}

- (int) numberOfViews
{
  return [_viewInfo count];
}

- (void) setFrame: (CPRect)frame
{
  if (CPEqualRects ([self frame], frame))
    {
      return;
    }

  [super setFrame: frame];
  
  if ([_viewInfo count] > 0)
    {
      var info;
      info = [_viewInfo objectAtIndex: 0];
      [_vManager forceLength: frame.size.height  ofLine: info._column];
      [_vManager updateLayout];
    }
  else
    {
      /* ... ? ... we need to save the forced height somewhere ... but
       * how do you remove the forcing afterwards ? */
    }

  [_hManager forceLength: frame.size.width  ofLine: _line];
  [_hManager updateLayout];
}

- (void) setFrameSize: (CPSize)size
{
  var oldSize = [self frame].size;
  
  if (oldSize.width == size.width && oldSize.height == size.height)
    {
      return;
    }

  [super setFrameSize: size];

  if ([_viewInfo count] > 0)
    {
      var info;
      info = [_viewInfo objectAtIndex: 0];
      [_vManager forceLength: size.height  ofLine: info._column];
      [_vManager updateLayout];
    }
  else
    {
      /* ... ? ... we need to save the forced height somewhere ... but
       * how do you remove the forcing afterwards ? */
    }

  [_hManager forceLength: size.width  ofLine: _line];
  [_hManager updateLayout];
}

- (void) setMinimumSize: (CPSize)aSize  forView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];
  
  info._minimumSize = aSize;
  
  [self pushToHManagerInfoForViewAtIndex: index];
  [self pushToVManagerInfoForViewAtIndex: index];
}

- (CPSize) minimumSizeForView: (CPView)aView
{
  var info = [self infoForView: aView];
  return info._minimumSize;
}


- (void) setHorizontalAlignment: (GSAutoLayoutAlignment)flag  
			forView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];
  var i, count;

  info._hAlignment = flag;

  /* Recompute the _hExpand and _hWeakExpand flags.  */
  _hExpand = NO;
  _hWeakExpand = NO;

  count = [_viewInfo count];

  for (i = 0; i < count; i++)
    {
      info = [_viewInfo objectAtIndex: i];
  
      if (info._hAlignment == GSAutoLayoutExpand)
	{
	  _hExpand = YES;
	}
      if (info._hAlignment == GSAutoLayoutWeakExpand)
	{
	  _hWeakExpand = YES;
	}
    }
  
  [self pushToHManagerInfoForViewAtIndex: index];
}

- (GSAutoLayoutAlignment) horizontalAlignmentForView: (CPView)aView
{
  var info = [self infoForView: aView];
  return info._hAlignment;
}


- (void) setVerticalAlignment: (GSAutoLayoutAlignment)flag  
		      forView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];
  var i, count;

  info._vAlignment = flag;

  /* Recompute the _vExpand and _vWeakExpand flags.  */
  _vExpand = NO;
  _vWeakExpand = NO;

  count = [_viewInfo count];

  for (i = 0; i < count; i++)
    {
      info = [_viewInfo objectAtIndex: i];
  
      if (info._vAlignment == GSAutoLayoutExpand)
	{
	  _vExpand = YES;
	}
      if (info._vAlignment == GSAutoLayoutWeakExpand)
	{
	  _vWeakExpand = YES;
	}
    }

  [self pushToVManagerInfoForViewAtIndex: index];
}

- (GSAutoLayoutAlignment) verticalAlignmentForView: (CPView)aView
{
  var info = [self infoForView: aView];
  return info._vAlignment;
}

- (void) setHorizontalBorder: (float)border  forView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];
  
  info._hBorder = border;
  
  [self pushToHManagerInfoForViewAtIndex: index];
} 

- (float) horizontalBorderForView: (CPView)aView
{
  var info = [self infoForView: aView];
  return info._hBorder;
}

- (void) setVerticalBorder: (float)border  forView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];

  info._vBorder = border;

  [self pushToVManagerInfoForViewAtIndex: index];
}

- (float) verticalBorderForView: (CPView)aView
{
  var info = [self infoForView: aView];
  return info._vBorder;
}

- (void) setProportion: (float)proportion
	       forView: (CPView)aView
{
  var info = [self infoForView: aView];
  var index = [_viewInfo indexOfObject: info];

  info._proportion = proportion;
  [self pushToHManagerInfoForViewAtIndex: index];
}

- (float) proportionForView: (CPView)aView
{
  var info = [self infoForView: aView];
  return info._proportion;
}

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  if (_hExpand)
    {
      return GSAutoLayoutExpand;
    }
  else if (_hWeakExpand)
    {
      return GSAutoLayoutWeakExpand;
    }
  else
    {
      return GSAutoLayoutAlignCenter;
    }
}

- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  if (_vExpand)
    {
      return GSAutoLayoutExpand;
    }
  else if (_vWeakExpand)
    {
      return GSAutoLayoutWeakExpand;
    }
  else
    {
      return GSAutoLayoutAlignCenter;
    }
}

- (float) autolayoutDefaultHorizontalBorder
{
  return 0;
}

- (float) autolayoutDefaultVerticalBorder
{
  return 0;
}

- (void) sizeToFitContent
{
  [self setFrameSize: [self minimumSizeForContent]];
}

- (CPSize) minimumSizeForContent
{
  /* Get it from the autolayout managers.  */
  var minimum={height: [_vManager minimumLineLength], width : [_hManager minimumLineLength]};

  return minimum;
}

- (void) setDisplayAutoLayoutContainers: (BOOL)flag
{
  [super setDisplayAutoLayoutContainers: flag];
  _displayAutoLayoutContainers = flag;
  [self setNeedsDisplay: YES];
}

- (void) drawRect: (CPRect)exposedRect
{
  if (_displayAutoLayoutContainers)
    {
      /* Draw a red line around ourselves.  */
      var bounds = [self bounds];

      [[CPColor redColor] set];
      CPFrameRect (bounds);

      /* Draw dotted red lines to display where we separate the
       * various boxes.  We want to display the lines exactly at the
       * boundaries of the line parts, so we get the line part
       * boundaries from the autolayout manager.  */
      {
	var i, count = [_hManager linePartCount];

	for (i = 0; i < count; i++)
	  {
	    var s;
	    
	    s = [_hManager layoutOfLinePartAtIndex: i];
	    
	    if (i > 0)
	      {
		/* We draw a dashed line between each line part and
		 * the previous one.  */
		var path;
		var dash = new Array( 1.0, 2.0 );
		
		path = [CPBezierPath bezierPath];
		[path setLineDash: dash  count: 2  phase: 0.0];
		[path moveToPoint: CPMakePoint (s.position, CPMinY (bounds))];
		[path lineToPoint: CPMakePoint (s.position, CPMaxY (bounds))];
		[path stroke];
	      }
	  }
      }
    }
}


@end

