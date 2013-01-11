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

GSAutoLayoutManagerChangedLayoutNotification = @"GSAutoLayoutManagerChangedLayoutNotification";

GSAutoLayoutStandardBox = 0;
GSAutoLayoutProportionalBox = 1;


CPOtherMouseDraggedMask=(1<<CPOtherMouseDragged);
CPZeroRect=CPMakeRect(0,0,0,0);
function CPEqualRects(aRect, bRect)
{ if( aRect.origin.x!=bRect.origin.x || aRect.origin.y!=bRect.origin.y ||  aRect.size.width!=bRect.size.width || aRect.size.height!=bRect.size.height) return NO;
	return YES;
}

/* This design is experimental and could be changed.  */

/*
 * There are potentially infinite ways in which you may want to
 * arrange your objects in a window. :-)
 *
 * Renaissance/AutoLayout provides a few classes which should allow
 * you to autolayout your objects, with a small effort, in
 * most standard cases.
 *
 * The basic intelligent objects in these classes are the
 * GSAutoLayoutManager objects.
 *
 * There are two main subclasses, GSAutoLayoutStandardManager and
 * GSAutoLayoutProportionalManager.  You are not supposed to create
 * other subclasses, and only rarely to interact with them directly -
 * autolayout managers are mainly used internally by the user-level
 * objects (boxes and grids).
 *
 * A single GSAutoLayoutManager performs the basic autolayout
 * operations on a line.  Basically, it manages a line, and decides
 * how to break the line into segments, or how to line up segments in
 * order to build up the line.  Additionally, the autolayout manager
 * can manage multiple lines at the same time, and break those lines
 * in segments (/build those lines from segments) in such a way that
 * the resulting layout for the different lines are related between
 * them: which means that all the lines must be of the same total
 * size, and that there is a general division of this total size in
 * parts, called line parts (which might have different sizes, eg,
 * line part 0 could be different from line part 1), and each segment
 * on each line takes up exactly a number of line parts (called the
 * 'span' of the segment; eg, the first segment on a line could have
 * span=1 and take line part 0 and the second one could have span=2
 * and take line part 1 and line part 2).  Different subclasses use
 * different criteria to determine the optimal division of the lines
 * in line parts. [To understand the requirement of supporting
 * multiple lines, think of a table.  Each row in the table is a line
 * to be broken in columns - the line parts; and all rows in the table
 * must be the same total size, and must be broken in line parts in a
 * similar way.  The cells are the segments; normally they have span 1
 * and each cell (segment) is inside a single column (line part), but
 * the system also supports a cell (segment) taking up two columns
 * (line parts).  In this framework all rows (lines) would share the
 * same autolayout manager)].
 *
 * The line parts form an invisible grid over which the segment are
 * placed.
 *
 * Finally, when an autolayout manager has made the layout with
 * segments, in each segment it aligns the `segment content' according
 * to the border and alignment which was specified for that segment.
 *
 * We consider all this the primitive autolayout operation, at least for
 * our boxes and grids.
 *
 * GSAutoLayoutManager is an abstract class; its concrete subclasses
 * provide different strategies of implementing this primitive
 * autolayout operation (eg, GSAutoLayoutStandardManager breaks the
 * line into line parts of unrelated size - while
 * GSAutoLayoutProportionalManager breaks the line into line parts of
 * equal (or proportional) size).
 *
 * To manage lines autolayout, a GSAutoLayoutManager needs some
 * information about what is to be displayed in the lines.  Clients
 * (usually box and grid objects) register themselves with the
 * GSAutoLayoutManager.  A client can register a line, and is given
 * back an id, which uniquely identify that line.  The client can then
 * update the autolayout manager information about that line (and the
 * segments contained in that line) at any time.  Whenever asked, the
 * autolayout manager performs full layout depending on the
 * information it has on the lines and segments.  When the autolayout
 * manager changes the layout of the lines, it posts a
 * GSAutoLayoutManagerChangedLayout notification, which the clients
 * should observe.  Once a client is informed that the layout has
 * changed, the client can request to the autolayout manager
 * information about the new way its line has been broken into
 * segments.
 *
 * This design is extremely general, but it's not extremely efficient.
 * Efficiency is irrelevant, since in normal conditions real window
 * layouts are composed of a few elements (a box normally does not
 * contain more than 10 elements).
 *
 * The GSAutoLayoutManager uses the following information on each
 * segment contained in a line:
 *
 *  - each segment on a line is identified by an integer, starting
 *  from 0 and going up.  The only importance of this integer is to
 *  allow the clients and the autolayout manager to have a way of
 *  identifying segments on a line, and to specify the sequence of
 *  segments on the line - segment 0 is always before segment 1 on the
 *  line etc.  Please note that - because of the span - there is no
 *  relationship between the numbers used in one line and on the other
 *  one (that is, you should not expect segment 4 on one line to be
 *  aligned with segment 4 on another line).  This number is really an
 *  internal identifier used between the client and the autolayout
 *  manager.  There can be no gaps in a line; to create visual gaps,
 *  you need to insert empty views that occupy a segment and display
 *  nothing in it.
 *
 *  - the left and right border of the segment.  These are used so that
 *  there can be some space around the segment content.
 *
 *  - the minimum size of the segment content.
 *
 *  - the minimum size of the segment - this is computed by summing up
 *  the left border, the right border, and the minimum size of the
 *  segment content.  The GSAutoLayoutManager, no matter what
 *  algorithm uses to break the line into segments, should never make
 *  a segment shorter than this size.
 *
 *  - the alignment type for the segment content.  This might either
 *  be expand, weak expand, center, min or max.  If the alignment is
 *  expand, then it means the segment likes to be expanded - that is,
 *  the minimum size is enough to display some information, but making
 *  the view bigger displays more information - so it's good.  Any
 *  other values means that the view already displays all its
 *  information in its minimum size; it's then a matter of aesthetics
 *  and taste to decide what to do if more space is available.  If the
 *  alignment type is 'expand', the autolayout manager should,
 *  whenever possible, try to expand the segment.  The behaviour when
 *  the alignment flag is something else might depend on the specific
 *  autolayout manager.  Generally, the autolayout manager will always
 *  try to expand segments with an alignment of expand, but can't
 *  guarantee that segments with another alignment won't be expanded
 *  too (if they are lined up with segments with an expand flag in
 *  another line, they will be expanded too).  If the segments get
 *  expanded, then the segment content is placed inside the segment
 *  according to the alignment flags: if it is either min, max or
 *  center, then this is how the segment contents are to be aligned
 *  inside the segment (after the border have been taken into
 *  accounts).  Finally, an alignment of 'weak expand' means that the
 *  segment contents doesn't like being expanded, but if the segment
 *  has to be expanded, then the segment contents should be expanded
 *  too for aesthetical reasons.
 *
 *  - a span (an integer) for the segment.  The default is 1.  This is
 *  is only meaningful when multiple lines are being laid out, in
 *  which case it is the number of line parts (the 'line parts' are an
 *  invisible grid over which the segments are placed; you can think
 *  of a line part as a 'column' when laying out the cells in a table
 *  row) that the segment takes up.  When the span is 1 for all
 *  segments, all segments in a line are numerated sequentially and,
 *  for example, segment 5 in one line is expected to have the same
 *  size as segment 5 in another line in the final layout.  When there
 *  are segments with a span which is not 1, then that's no longer
 *  necessarily true.
 *  
 * It is also possible to set information for specific line parts:
 *
 *  - the minimum size of the line part.  Useful when managing
 *  multiple lines, eg, you can set a minimum size for a column in a
 *  table.
 *
 *  - a flag to mark the column as expand or wexpand.  Useful when
 *  managing multiple lines, eg, you can decide that you want a column
 *  in a table to expand in preference to another one.
 *
 *  - a proportion (a float) for the line part.  The default is 1.  A
 *  GSAutoLayoutProportionalManager interprets it as a scaling of the
 *  number of basic units that the line part takes up.  Eg, a line
 *  part with proportion=2 would automatically have double the size of
 *  one with proportions=1.  If you think of the line parts as the
 *  'columns' in a line, then a proportion of 1 for all of them means
 *  that all columns have exactly the same size; changing the
 *  proportion of a column makes it bigger/smaller compared to the
 *  other ones.  The standard manager ignores this information.
 */

/* This struct is used to store and return layout information for a
 * segment (or line part).  */

/* This class is just a place to store segment information.  */
@implementation GSAutoLayoutManagerSegment: CPObject
{
  /* All the ivars are public, we set/read them directly.  */

  /* The minimum length of the segment contents.  */
  float _minimumContentsLength;

  /* The min border of the segment.  */
  float _minBorder;
  
  /* The max border of the segment.  */
  float _maxBorder;

  /* 0 if the segment should be expanded when possible, because that
   * would show additional information; > 0 if there is no additional
   * information to show, and so the segment looks only uglier when
   * expanded, and it's better not to expand it; in case > 0, then the
   * value can be 1, 2, 3, 4 meaning if in case the segment really
   * must be expanded, to expand it, or how to align the segment
   * contents inside the segment, if left, center, or right.  Because
   * 0 is determined by a functional reason, while > 0 by an
   * aesthetical reason, 0 should be strictly honoured, at the expense
   * of not always honouring > 0.
   */
  GSAutoLayoutAlignment _alignment;

  /* This number holds the line part in the line where the segment
   * starts.  Typically used to interact with other segments and
   * lines.  Please note that this information is regenerated each
   * time the minimum layout is done.  */
  int _linePart;

  /* This number holds the number of line parts in the line that the
   * segment takes up.  Typically used to interact with other segments
   * and lines.  */
  int _span;

  /* The layout of the segment once minimum layout is done.  */
  GSAutoLayoutSegmentLayout _minimumLayout;

  /* The layout of the segment once layout is done.  */
  GSAutoLayoutSegmentLayout _layout;

  /* The layout of the segment contents once layout is done.  This is
   * the final computation result which we serve to clients.  */
  GSAutoLayoutSegmentLayout _contentsLayout;
}
- (id) init
{	_minimumLayout={position:0, length:0};
  _layout={position:0, length:0};

  _contentsLayout={position:0, length:0};

  /* Set the span because this is essential to compute the line parts.
   * It must always be an integer > 0.
   */
  _span = 1;

  return self;
}

@end

/* This class is just a place to store line part information.  */
@implementation GSAutoLayoutManagerLinePartInformation: CPObject
{
  /* All the ivars are public, we set/read them directly.  */

  /* The minimum length of the line part (no distinction between
   * borders/content since a line part has no border/content).  This
   * can be used to set a minimum size for rows or columns in grids.
   */
  float _minimumLength;
  
  /* This is the number of grid units that the line part takes up for
   * proportional layout managers; eg, a line part with _proportion=2
   * will have double the size of one with _proportion=1.  Ignored by
   * standard managers.  */
  float _proportion;

  /* This can be set programmatically to have the line part always
   * expand even if the views inside it are not set to.  */
  BOOL _alwaysExpands;

  /* This can be set programmatically to have the line part never
   * expand even if the views inside it are set to.  */
  BOOL _neverExpands;
}
- (id) init
{
  return self;
}
@end

/* Objects of this class represent a line part that is used during
 * layout.  This information is collected/computed during
 * autolayout.  */
@implementation GSAutoLayoutManagerLinePart: CPObject
{
  /* All the ivars are public, we set/read them directly.  */

  /* Any special/hardcoded info that we might have on the line part
   * (stored here to avoid continuous lookups in the
   * _linePartInformation dictionary during autolayout); normally set
   * to nil.  */
  GSAutoLayoutManagerLinePartInformation _info;

  /* If the line part expands (determined from the _alwaysExpands and
   * _neverExpands flags, and the alignment of the segments that are
   * displayed inside the line part).  */
  BOOL _expands;

  /* The proportion, used only by the proportional autolayout manager.  */
  float _proportion;

  /* The layout of the line part once minimum layout is done.  */
  GSAutoLayoutSegmentLayout _minimumLayout;

  /* The layout of the line part once layout is done.  */
  GSAutoLayoutSegmentLayout _layout;
}
- (id) initWithInfo: (GSAutoLayoutManagerLinePartInformation) info
{
  _minimumLayout = {position:0, length:0};

  _layout = {position:0, length:0};

  _info = info;

  return self;
}

@end

/* This class contains a little more logic - allocates the segment
 * array, frees it.  */
@implementation GSAutoLayoutManagerLine: CPObject
{
  /* The forced length of the line, or < 0 if none.  */
  float _forcedLength;

  /* An array of GSAutoLayoutManagerSegment (or a subclass) objects.
   * Created/destroyed when the object is created/destroyed, but for
   * the rest managed directly by the GSAutoLayoutManager.  */
  NSMutableArray _segments;
}

- (id) init
{
  _segments = [CPMutableArray new];
  _forcedLength = -1;
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

@end

/* The main class.  */
@implementation GSAutoLayoutManager: CPObject
{
  /* The GSAutoLayoutManagerLine objects, which store the information
   * on each segment, and the final autolayout information.  */
  CPMutableSet _lines;

  /* A dictionary that maps a line part index (as a NSNumber) to an
   * GSAutoLayoutManagerLineInformationPart object.  Used to store
   * information on line parts that have special settings.  */
  CPMutableDictionary _linePartInformation;

  /* The following array is created and populated during an autolayout
   * update/computation.  First, we create the _lineParts array that
   * is an array of GSAutoLayoutManagerLinePart objects, each of which
   * includes all information on that specific line part; then, we
   * compute the minimum layout of the line parts; then, we do the
   * full layout by allocating the excess size to the various line
   * parts.  Finally, we can then use the final linePart autolayout to
   * generate the autolayout information stored in the _lines array.
   */
  CPMutableArray _lineParts;

  /* The minimum length of the lines.  */
  float _minimumLength;

  /* The current length of the lines.  */
  float _length;

  /* If we need to recompute the minimum layout.  Set to YES when
   * a segment's attribute changes.  */
  BOOL _needsUpdateMinimumLayout;

  /* If we need to recompute the layout.  Set to YES when a line's
   * forced length is changed.  */
  BOOL _needsUpdateLayout;
}

- (id) init
{
  _lines = [CPMutableSet new];
  _linePartInformation = [CPMutableDictionary new];
  _lineParts = [CPMutableArray new];
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) updateLayout
{
  if (_needsUpdateMinimumLayout)
    {
      if ([self internalUpdateMinimumLayout])
	{
	  _needsUpdateLayout = YES;
	}

      _needsUpdateMinimumLayout = NO;
    }
  
  if (_needsUpdateLayout)
    {
      /* First, compute the forced _length.  */
      var e = [_lines objectEnumerator];
      var line;
      _length = -1;

      while ((line = [e nextObject]) != nil) 
	{
	  var forcedLength = line._forcedLength;
	  if (forcedLength < 0)
	    {
	      /* no forced length for this line - ignore */
	    }
	  else
	    {
	      if (_length < 0)
		{
		  /* First forcedLength we find - use it as it is.  */
		  _length = forcedLength;
		}
	      else
		{
		  /* A new forcedLength - use it only if less than what
		   * we already have.  */
		  _length = min (forcedLength, _length);
		}
	    }
	}

      /* If there is no forced length, use _minimumLength.  */
      if (_length < 0)
	{
	  _length = _minimumLength;
	}

      /* Please note that it is possible that _length <
       * _minimumLength; in which case, in internalUpdateLayout, we
       * use the minimum layout.  */

      if ([self internalUpdateLayout])
	{
	  /* Post the notification that the layout changed.  Clients
	   * should observe this notification, and update themselves
	   * as a consequence of layout changes when they get this
	   * notification.  */
	  [[CPNotificationCenter defaultCenter]
	    postNotificationName: GSAutoLayoutManagerChangedLayoutNotification
	    object: self
	    userInfo: nil];
	}
      
      _needsUpdateLayout = NO;
    }
}

- (void) internalUpdateLineParts
{
  /* Determine the number of line parts.  */
  var e = [_lines objectEnumerator];
  var line;
  var i, numberOfLineParts = 0;

  [_lineParts removeAllObjects];
  
  while ((line = [e nextObject]) != nil) 
    {
      var linePartCount = 0;
      var count = [line._segments count];

      for (i = 0; i < count; i++)
	{
	  var segment;
	  
	  segment = [line._segments objectAtIndex: i];
	  segment._linePart = linePartCount;
	  linePartCount += segment._span;
	}
      numberOfLineParts = Math.max(linePartCount, numberOfLineParts);
    }

  for (i = 0; i < numberOfLineParts; i++)
    {
      var linePart;
      var linePartInfo;
      
      /* Store any special information that was set/hardcoded for that
       * specific line part.  */
      linePartInfo = [_linePartInformation objectForKey: [CPNumber numberWithInt: i]];
      linePart = [[GSAutoLayoutManagerLinePart alloc] initWithInfo: linePartInfo];
      [_lineParts addObject: linePart];
      }
}

- (void) internalUpdateSegmentsMinimumLayoutFromLineParts
{
  /* Iterate over all segments, and set their minimumLayout.  */
  var e = [_lines objectEnumerator];
  var line;
  
  e = [_lines objectEnumerator];
  
  while ((line = [e nextObject]) != nil) 
    {
      var i, count = [line._segments count];

      for (i = 0; i < count; i++)
	{
	  var segment;
	  var j;

	  segment = [line._segments objectAtIndex: i];
	  (segment._minimumLayout).length = 0;
	  
	  for (j = 0; j < segment._span; j++)
	    {
	      var linePart;
	      
	      linePart = [_lineParts objectAtIndex: segment._linePart + j];

	      if (j == 0)
		{
		  (segment._minimumLayout).position = (linePart._minimumLayout).position;
		}
	      
	      (segment._minimumLayout).length += (linePart._minimumLayout).length;
	    }
	  
	  /* We do not need to layout segment contents inside the
	   * segment in the minimum layout.  The minimum layout is
	   * never used to actually draw anything on screen, so we can
	   * skip this operation.  When the actual layout is computed,
	   * then we will layout the segment contents inside the final
	   * layout; this will be stored in the _contentsLayout part
	   * of the segment.
	   */
	}
    }
}

- (void) internalUpdateSegmentsLayoutFromLineParts
{
  /* Iterate over all segments, and set their layout.  */
  var e = [_lines objectEnumerator];
  var line;
  
  e = [_lines objectEnumerator];
  
  while ((line = [e nextObject]) != nil) 
    {
      var i, count = [line._segments count];

      for (i = 0; i < count; i++)
	{
	  var segment;
	  var j;

	  segment = [line._segments objectAtIndex: i];
	  (segment._layout).length = 0;
	  
	  for (j = 0; j < segment._span; j++)
	    {
	      var linePart;
	      
	      linePart = [_lineParts objectAtIndex: segment._linePart + j];

	      if (j == 0)
		{
		  (segment._layout).position = (linePart._layout).position;
		}
	      
	      (segment._layout).length += (linePart._layout).length;
	    }

	  /* Now place the segment contents inside the segment.  */

	  {
	    /* First, start with the segment, then remove the fixed
	     * borders.  */
	    var s = segment._layout;
	    
	    /* Now, align the segment contents in the resulting space.  */
	    switch (segment._alignment)
	      {
	      case GSAutoLayoutExpand:
	      case GSAutoLayoutWeakExpand:
		{
		  s.position += segment._minBorder;
		  s.length -= segment._minBorder + segment._maxBorder;
		  break;
		}
	      case GSAutoLayoutAlignMin:
		{
		  s.position += segment._minBorder;
		  s.length = segment._minimumContentsLength;
		  break;
		}
	      case GSAutoLayoutAlignMax:
		{
		  s.position += s.length - segment._maxBorder - segment._minimumContentsLength;
		  s.length = segment._minimumContentsLength;
		  break;
		}
	      case GSAutoLayoutAlignCenter:
	      default:
		{
		  s.position += ((s.length - segment._minimumContentsLength) / 2);
		  s.length = segment._minimumContentsLength;
		  break;
		}
	      }

	    /* Save the results of our computations.  */
	    segment._contentsLayout = s;
	  }
	}
    }
}

- (BOOL) internalUpdateMinimumLayout
{
  /* Subclass responsibility.  */
  return NO;
}

- (BOOL) internalUpdateLayout
{
  /* Subclass responsibility.  */
  return NO;
}

- (id) addLine
{
  var line;

  line = [GSAutoLayoutManagerLine new];
  [_lines addObject: line];
  _needsUpdateMinimumLayout = YES;
  _needsUpdateLayout = YES;

  /* We are funny here ;-) ... we return the line itself as `an
   * identifier to identify that line which clients can use to
   * identify that line with the autolayout manager'.  This saves up
   * any lookup to find the line object.  Of course clients should
   * *NEVER* touch the line object we gave them - we might even change
   * our implementation and pass them something else - a real
   * identifier perhaps.  */
  return line;
}

- (void) removeLine: (id)line
{
  [_lines removeObject: line];
  _needsUpdateMinimumLayout = YES;
  _needsUpdateLayout = YES;
}

- (void) forceLength: (float)length
	      ofLine: (id)line
{
  var l = line;
  if (l._forcedLength != length)
    {
      _needsUpdateLayout = YES;
      l._forcedLength = length;
    }
}

- (void) insertNewSegmentAtIndex: (int)segment
			  inLine: (id)line
{
  var s;
  var l = line; 

  s = [GSAutoLayoutManagerSegment new];
  [l._segments insertObject: s  atIndex: segment];
  _needsUpdateMinimumLayout = YES;
  _needsUpdateLayout = YES;
}

- (void) removeSegmentAtIndex: (int)segment
		       inLine: (id)line
{
  var l = line; 

  [l._segments removeObjectAtIndex: segment];
  _needsUpdateMinimumLayout = YES;
  _needsUpdateLayout = YES;
}

- (unsigned int) segmentCountInLine: (id)line
{
  var l = line;
  
  return [l._segments count];
}

- (unsigned int) linePartCount
{
  return [_lineParts count];
}

- (unsigned int) linePartCountInLine: (id)line
{
  var l = line;
  var linePartCount = 0;
  var i, count = [l._segments count];

  for (i = 0; i < count; i++)
    {
      var segment = [l._segments objectAtIndex: i];
      linePartCount += segment._span;
    }

  return linePartCount;
}

- (void) setMinimumLength: (float)min
		alignment: (GSAutoLayoutAlignment)flag
		minBorder: (float)minBorder
		maxBorder: (float)maxBorder
		     span: (int)span
	 ofSegmentAtIndex: (int)segment
		   inLine: (id)line;
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];

  if (s._minimumContentsLength != min)
    {
      s._minimumContentsLength = min;
      _needsUpdateMinimumLayout = YES;
    }
  
  if (s._alignment != flag)
    {
      s._alignment = flag;
      _needsUpdateMinimumLayout = YES;
    }
  
  if (s._minBorder != minBorder)
    {
      s._minBorder = minBorder;
      _needsUpdateMinimumLayout = YES;
    }

  if (s._maxBorder != maxBorder)
    {
      s._maxBorder = maxBorder;
      _needsUpdateMinimumLayout = YES;
    }

  if (s._span != span)
    {
      if (span > 0)
	{
	  s._span = span;
	  _needsUpdateMinimumLayout = YES;
	}
      else
	{
	  CPLog (@"GSAutoLayoutManager: Warning, segment has non-positive span %d.  Ignored", 
		 span);
	}
    }
}

- (float) minimumLengthOfSegmentAtIndex: (int)segment
				 inLine: (id)line
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];

  return s._minimumContentsLength;
}


- (GSAutoLayoutAlignment) alignmentOfSegmentAtIndex: (int)segment
					     inLine: (id)line
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];

  return s._alignment;  
}

- (float) minBorderOfSegmentAtIndex: (int)segment
			     inLine: (id)line
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];

  return s._minBorder;  
}

- (float) maxBorderOfSegmentAtIndex: (int)segment
			     inLine: (id)line
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];

  return s._maxBorder;  
}

- (int) spanOfSegmentAtIndex: (int)segment
		      inLine: (id)line
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];

  return s._span;
}

- (void) setMinimumLength: (float)min
	    alwaysExpands: (BOOL)alwaysExpands
	     neverExpands: (BOOL)neverExpands
	       proportion: (float)proportion
	ofLinePartAtIndex: (int)linePart
{
  var info = [GSAutoLayoutManagerLinePartInformation new];

  info._minimumLength = min;
  info._alwaysExpands = alwaysExpands;
  info._neverExpands = neverExpands;
  info._proportion = proportion;

  [_linePartInformation setObject: info
			forKey: [CPNumber numberWithInt: linePart]];
  _needsUpdateMinimumLayout = YES;
}

- (float) proportionOfLinePartAtIndex: (int)linePart
{
  var info;

  info = [_linePartInformation objectForKey: [CPNumber numberWithInt: linePart]];

  if (info == nil)
    {
      return 1.0;
    }
  else
    {
      return info._proportion;
    }
}

- (float) minimumLengthOfLinePartAtIndex: (int)linePart
{
  var info;

  info = [_linePartInformation objectForKey: [CPNumber numberWithInt: linePart]];

  if (info == nil)
    {
      return 0.0;
    }
  else
    {
      return info._minimumLength;
    }
}

- (BOOL) alwaysExpandsOfLinePartAtIndex: (int)linePart
{
  var info;

  info = [_linePartInformation objectForKey: [CPNumber numberWithInt: linePart]];

  if (info == nil)
    {
      return NO;
    }
  else
    {
      return info._alwaysExpands;
    }
}

- (BOOL) neverExpandsOfLinePartAtIndex: (int)linePart
{
  var info;

  info = [_linePartInformation objectForKey: [CPNumber numberWithInt: linePart]];

  if (info == nil)
    {
      return NO;
    }
  else
    {
      return info._neverExpands;
    }
}

- (void) removeInformationOnLinePartAtIndex: (int)linePart
{
  [_linePartInformation removeObjectForKey: [CPNumber numberWithInt: linePart]];
}

- (float) lineLength
{
  return _length;
}


- (GSAutoLayoutSegmentLayout) layoutOfSegmentAtIndex: (int)segment
					      inLine: (id)line
{
  var l = line;
  var s = [l._segments objectAtIndex: segment];
  
  return s._contentsLayout;
}

- (GSAutoLayoutSegmentLayout) layoutOfLinePartAtIndex: (int)linePart
{
  var l = [_lineParts objectAtIndex: linePart];

  return l._layout;
}

- (float) minimumLineLength
{
  return _minimumLength;
}

@end
