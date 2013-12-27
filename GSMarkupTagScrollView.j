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


@implementation GSMarkupTagScrollView: GSMarkupTagView

+ (CPString) tagName
{
  return @"scrollView";
}

+ (Class) platformObjectClass
{
  return [CPScrollView class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [platformObject init];
  
  /* hasHorizontalScroller (FIXME name) */
  if ([self boolValueForAttribute: @"hasHorizontalScroller"] == 0)
    {
      [platformObject setHasHorizontalScroller: NO];
    }
  else
    {
      [platformObject setHasHorizontalScroller: YES];
    }
  

  /* hasVerticalScroller (FIXME name) */  
  if ([self boolValueForAttribute: @"hasVerticalScroller"] == 0)
    {
      [platformObject setHasVerticalScroller: NO];
    }
  else
    {
      [platformObject setHasVerticalScroller: YES];
    }

/* borderType - if none is given, the default is Bezel on GNUstep and
 * none on Apple Mac OS X.  This attribute is called 'borderType', and
 * not 'border', because 'border' is already used for autolayout
 * purposes.  You should use sparingly this attribute - usually you
 * can/should allow the default border type for your platform to be
 * used.
 */
  {
    var theType = CPNoBorder;    /* Default on Apple Mac OS X */
    var border = [_attributes objectForKey: @"borderType"];
    
    if (border != nil)
      {
	if ([border isEqualToString: @"none"] == YES)
	  {
	    theType = CPNoBorder;
	  }
	else if ([border isEqualToString: @"line"] == YES)
	  {
	    theType = CPLineBorder;
	  }
	else if ([border isEqualToString: @"bezel"] == YES)
	  {
	    theType =  CPBezelBorder;
	  }
	else if ([border isEqualToString: @"groove"] == YES)
	  {
	    theType =  CPGrooveBorder;
          }
      }
    
    [platformObject setBorderType: theType];
  }
  
  /* Add content.  */
  {
    if ([_content count] > 0)
      {
	var view = [_content objectAtIndex: 0];
	var v;
	
	v = [view platformObject];
	if (v != nil  &&  [v isKindOfClass: [CPView class]])
	  {
	    [platformObject setDocumentView: v];
	    /* I think this is a bug in gnustep's gui library:
	     * CPClipView has autoresizesSubviews set, I'm not sure
	     * why.  */
		var mymask=CPViewNotSizable;
		if(![platformObject hasHorizontalScroller])
		{	mymask|= CPViewWidthSizable;
			var myrect = [[platformObject contentView] frame];
			var contentRect = [[platformObject documentView] frame];
			contentRect.size.width=myrect.size.width;
			[[platformObject documentView] setFrame: contentRect];
		}
	    [v setAutoresizingMask: mymask];
	  }
      }
  }

  return platformObject;
}

- (id) postInitPlatformObject: (id)platformObject
{
  platformObject = [super postInitPlatformObject: platformObject];

  /* FIXME - not sure how to set up this stuff for text view, if not
   * here.  */
  if ([[platformObject documentView] isKindOfClass: [CPTextView class]])
    {
      var textRect = [[platformObject contentView] frame];
      var tv = [platformObject documentView];
      
      [tv setFrame: textRect];
      [tv setHorizontallyResizable: NO];
      [tv setVerticallyResizable: YES];
      [tv setMinSize: CPMakeSize (0, 0)];
      [tv setMaxSize: CPMakeSize (1E7, 1E7)];
      [tv setAutoresizingMask: CPViewHeightSizable | CPViewWidthSizable];
      [[tv textContainer] setContainerSize: CPMakeSize 
			  (textRect.size.width, 1e7)];
      [[tv textContainer] setWidthTracksTextView: YES];
    }
	var width=[self intValueForAttribute:"width"];
	if(width)
	{	var myrect = [[platformObject contentView] frame];
		myrect.size.width=width;
		[[platformObject contentView] setFrame: myrect];
	}



  return platformObject;
}

@end
