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

@import "GSAutoLayoutManager.j"
@implementation GSAutoLayoutStandardManager : GSAutoLayoutManager
{
  /* Cached number of line parts with expand set to YES.  Computed
   * during minimum layout.  */
  int _numberOfExpandingLineParts;
}


- (id) init
{
  return [super init];
}

- (void) dealloc
{
  [super dealloc];
}

- (BOOL) internalUpdateMinimumLayout
{
  /* Identify the special segments with span != 1 and store
   * them in this array.
   */
  var specialSegments = [CPMutableArray new];
  var e = [_lines objectEnumerator];
  var line;

  while ((line = [e nextObject]) != nil) 
    {
      var i, count = [line._segments count];
      
      for (i = 0; i < count; i++)
	{
	  var segment;
	  
	  segment = [line._segments objectAtIndex: i];
	  if (segment._span > 1)
	    {
	      [specialSegments addObject: segment];
	    }
	}
    }

  [self internalUpdateLineParts];

  /* We now work on the _minimumLayout of the line parts; please note
   * that we only work on the length for now, and ignore the
   * position.  */

  /* If there are any minimumLength set for line parts, set them as
   * initial lengths for them.  */
  {
    var i, count = [_lineParts count];
    for (i = 0; i < count; i++)
      {
	var linePart;
	var linePartInfo;
	
	linePart = [_lineParts objectAtIndex: i];
	linePartInfo = linePart._info;
	
	if (linePartInfo != nil)
	  {
	    (linePart._minimumLayout).length = linePartInfo._minimumLength;

	    /* Since we're there, also set the expand flag.  Just in
	     * case we never work on this line part again.  */
	    if (linePartInfo._alwaysExpands == YES)
	      {
		linePart._expands = YES;
	      }
	  }
      }
  }
  
  /* Now determine the minimum length of each line part, ignoring
   * special segments.  */
  e = [_lines objectEnumerator];
  
  while ((line = [e nextObject]) != nil) 
    {
      var i, count = [line._segments count];
      
      for (i = 0; i < count; i++)
	{
	  var segment;
	  
	  segment = [line._segments objectAtIndex: i];
	  
	  if (segment._span > 1)
	    {
	      /* ignore (for now - it will be dealt with in the
	       * second loop below).  */
	    }
	  else
	    {
	      /* Update autolayout information on this line part:
	       * consider the existing _minimumLayout.length, the
	       * minimLength of this segment, and any _minimumLength
	       * set for the line part.  Also update information on
	       * the expand flag.
	       */
	      var linePart;
	      var minLinePartLength;

	      linePart = [_lineParts objectAtIndex: segment._linePart];

	      minLinePartLength = segment._minBorder 
		+ segment._minimumContentsLength 
		+ segment._maxBorder;

	      minLinePartLength = Math.max ((linePart._minimumLayout).length,
				       minLinePartLength);

	      if (segment._alignment == GSAutoLayoutExpand
		  || segment._alignment == GSAutoLayoutWeakExpand)
		{
		  linePart._expands = YES;
		}
	      
	      /* Use any special information that was set for this
	       * line part.  */
	      {
		var info;
		info = linePart._info;
		
		if (info != nil)
		  {
		    /* info._minimumLength and info._alwaysExpand
		     * have already been dealt with.  */
		    if (info._neverExpands == YES)
		      {
			linePart._expands = NO;
		      }
		  }
	      }

	      (linePart._minimumLayout).length = minLinePartLength;
	    }
	}
    }

  /* Now work out what to do with the special segments.  */
  {
    var i, count = [specialSegments count];

    for (i = 0; i < count; i++)
      {
	var segment;
	var j;
	var length = 0;
	var linePartsWhichExpand = 0;
	var segmentMinimumLength;

	segment = [specialSegments objectAtIndex: i];

	segmentMinimumLength = segment._minBorder 
	  + segment._minimumContentsLength + segment._maxBorder;
	
	/* Compute the (current) total length of the line parts
	 * spanned by this segment.  */
	for (j = 0; j < segment._span; j++)
	  {
	    var linePart;

	    linePart = [_lineParts objectAtIndex: segment._linePart + j];
	    length += (linePart._minimumLayout).length;
	    if (linePart._expands)
	      {
		linePartsWhichExpand++;
	      }
	  }

	/* If it's not enough to display the segment, expand the
	 * line parts.  */
	if (length < segmentMinimumLength)
	  {
	    /* If some line parts are marked as expanding, expand them
	     * rather than the line parts not marked as expanding.  */
	    if (linePartsWhichExpand > 0)
	      {
		var enlargeBy = (segmentMinimumLength - length) 
		  / linePartsWhichExpand;

		for (j = 0; j < segment._span; j++)
		  {
		    var linePart;
		   
		    linePart = [_lineParts objectAtIndex: segment._linePart + j];
		    if (linePart._expands)
		      {
			(linePart._minimumLayout).length += enlargeBy;
		      }
		  }
	      }
	    else
	      {
		/* Else expands all line parts of the same amount to
		 * distribute the ugliness on all line parts.  */
		var enlargeBy = (segmentMinimumLength - length) 
		  / segment._span;

		for (j = 0; j < segment._span; j++)
		  {
		    var linePart;
		   
		    linePart = [_lineParts objectAtIndex: segment._linePart + j];
		    (linePart._minimumLayout).length += enlargeBy;
		  }
	      }
	  }

	/* If the segment might need to expand in the future, but no
	 * line parts expand, then mark them all as expanding to
	 * distribute the ugliness between all of them.  */
	if ((segment._alignment == GSAutoLayoutExpand
	     || segment._alignment == GSAutoLayoutWeakExpand)
	    &&  linePartsWhichExpand == 0)
	  {
	    for (j = 0; j < segment._span; j++)
	      {
		var linePart;

		linePart = [_lineParts objectAtIndex: segment._linePart + j];
		linePart._expands = YES;
	      }
	  }
      }
  }

  /* First, compute the _minimumLayout.position of all line parts.  */
  {
    var position = 0;
    var i, count = [_lineParts count];

    for (i = 0; i < count; i++)
      {
	var linePart;
	
	linePart = [_lineParts objectAtIndex: i];
	(linePart._minimumLayout).position = position;
	position += (linePart._minimumLayout).length;
      }

    _minimumLength = position;
  }  

  /* Then, propagate the minimum layout to all segments.  */
  [self internalUpdateSegmentsMinimumLayoutFromLineParts];

  /* Cache the number of expanding line parts.  */
  _numberOfExpandingLineParts = 0;

  {
    var i, count = [_lineParts count];

    for (i = 0; i < count; i++)
      {
	var linePart = [_lineParts objectAtIndex: i];
	
	if (linePart._expands)
	  {
	    _numberOfExpandingLineParts++;
	  }
      }
  }
  
  /* TODO - really check if something changed or not and return NO if
   * not.  */
  return YES;
}


- (BOOL) internalUpdateLayout
{
  var enlargeBy;

  if (_length < _minimumLength)
    {
      /* We are being constrained below our minimum size ... adopt the
       * minimum layout for views.  */
      enlargeBy = 0;
    }
  else
    {
      if (_numberOfExpandingLineParts == 0)
	{
	  /* OK - we have no line parts that want to expand.  We just
	   * do nothing.  The views will be displayed in their minimum
	   * layout, and the rest of the space will be empty.  */
	  enlargeBy = 0;
	}
      else
	{
	  enlargeBy = (_length - _minimumLength) / _numberOfExpandingLineParts;
	}
    }

  {
    var i, numberOfLineParts = [_lineParts count];
    var positionDrift = 0;
    
    for (i = 0; i < numberOfLineParts; i++)
      {
	var linePart = [_lineParts objectAtIndex: i];
	
	(linePart._layout).position = (linePart._minimumLayout).position + positionDrift;

	if (linePart._expands)
	  {
	    (linePart._layout).length = (linePart._minimumLayout).length + enlargeBy;
	    positionDrift += enlargeBy;
	  }
	else
	  {
	    (linePart._layout).length = (linePart._minimumLayout).length;	  
	  }
      }
  }

  [self internalUpdateSegmentsLayoutFromLineParts];

  /* TODO - only return YES if something changed in the layout ! */
  /* Idea - the superclass could check ?  */
  return YES;
}

@end

