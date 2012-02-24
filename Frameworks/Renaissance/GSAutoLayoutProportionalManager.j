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

@implementation GSAutoLayoutProportionalManager : GSAutoLayoutManager
{
  float _minimumLayoutUnit;
  
  float _layoutUnit;
}


- (BOOL) internalUpdateMinimumLayout
{
  _minimumLayoutUnit = 0;

  [self internalUpdateLineParts];

  /* Determine the minimum layout unit for line parts.  Also, cache
   * its proportion (and safety-check that they are all positive).  */
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
	    var minimumLayoutUnit;

	    /* Ignore meaningless proportion <= 0.  */
	    if (linePartInfo._proportion > 0)
	      {
		minimumLayoutUnit = (linePartInfo._minimumLength / linePartInfo._proportion);
		_minimumLayoutUnit = Math.max(_minimumLayoutUnit, minimumLayoutUnit);
		linePart._proportion = linePartInfo._proportion;
	      }
	    else
	      {
		CPLog (@"GSAutoLayoutProportionalManager: Warning, line part has non-positive proportion %f.  Ignoring.",
		       linePartInfo._proportion);
		linePart._proportion = 1.0;
	      }
	  }
	else
	  {
	    linePart._proportion = 1.0;
	  }
      }
  }

  /* Determine the minimum layout unit for segments.  */
  {
    var e = [_lines objectEnumerator];
    var line;
    
    while ((line = [e nextObject]) != nil) 
      {
	var i, count = [line._segments count];
	
	for (i = 0; i < count; i++)
	  {
	    var segment;
	    var j;
	    var proportion = 0;

	    segment = [line._segments objectAtIndex: i];
	    
	    for (j = 0; j < segment._span; j++)
	      {
		var linePart;
		
		linePart = [_lineParts objectAtIndex: segment._linePart + j];
		proportion += linePart._proportion;
	      }

	    {
	      var segmentMinLayoutUnit;
	      var segmentMinLength;

	      segmentMinLength = segment._minBorder 
		+ segment._minimumContentsLength + segment._maxBorder;
	      segmentMinLayoutUnit = segmentMinLength / proportion;

	      _minimumLayoutUnit = Math.max(segmentMinLayoutUnit, _minimumLayoutUnit);
	    }
	  }
      }
  }

  /* Now, compute the _minimumLayout of all line parts.  */
  {
    var position = 0;
    var i, count = [_lineParts count];
    
    for (i = 0; i < count; i++)
      {
	var linePart;
	
	linePart = [_lineParts objectAtIndex: i];
	(linePart._minimumLayout).position = position;
	(linePart._minimumLayout).length = _minimumLayoutUnit * linePart._proportion;
	
	position += (linePart._minimumLayout).length;
      }
    
    _minimumLength = position;
  }  

  /* Then, propagate the minimum layout to all segments.  */
  [self internalUpdateSegmentsMinimumLayoutFromLineParts];

  /* TODO - really check if something changed or not and return NO if
   * not.  */
  return YES;
}


- (BOOL) internalUpdateLayout
{
  /* Please note that this method is very different from the
   * 'standard' internalUpdateLayout.  For example, if you have two
   * line parts which expand, in the standard layout manager they get
   * expanded equally.  In the proportional one, they get expanded in
   * proportion to their 'proportion', eg, one could expand x2 the
   * other.
   */

  /* Compute the new layoutUnit.  */
  if (_length < _minimumLength)
    {
      /* We are being constrained below our minimum size ... adopt the
       * minimum layout for views.  */
      _layoutUnit = _minimumLayoutUnit;
    }
  else if (_minimumLength != 0)
    {
      _layoutUnit = (_length * _minimumLayoutUnit) / _minimumLength;
    }
  else
    {
      /* This would be puzzling.  I suppose it could happen if you
       * only put a <hspace /> in an <hbox>, for example.  In that
       * case, well just divide the _length by the number of units and
       * accept the result as our _layoutLength.  This is equivalent
       * to the computation above when _minimumLength is not zero,
       * but also works when it's zero.  */
      {
	var totalNumberOfLayoutUnits = 0;
	var i, count = [_lineParts count];
	
	for (i = 0; i < count; i++)
	  {
	    var linePart;
	    
	    linePart = [_lineParts objectAtIndex: i];
	    totalNumberOfLayoutUnits += linePart._proportion;
	  }
	
	if (totalNumberOfLayoutUnits != 0)
	  {
	    _layoutUnit = _length / totalNumberOfLayoutUnits;
	  }
	else
	  {
	    /* Nothing to display, zero is as good as any other number.  */
	    _layoutUnit = 0;
	  }
      }
    }

  /* Now, compute the _layout of all line parts.  */
  {
    var position = 0;
    var i, count = [_lineParts count];
    
    for (i = 0; i < count; i++)
      {
	var linePart;
	
	linePart = [_lineParts objectAtIndex: i];
	(linePart._layout).position = position;
	(linePart._layout).length = _layoutUnit * linePart._proportion;
	
	position += (linePart._layout).length;
      }
  }  

  [self internalUpdateSegmentsLayoutFromLineParts];

  /* TODO - only return YES if something changed in the layout ! */
  return YES;
}


@end

