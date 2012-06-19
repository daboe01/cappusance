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
@import "GSAutoLayoutVBox.j"

@implementation GSMarkupTagVbox: GSMarkupTagView

+ (CPString) tagName
{
  return @"vbox";
}

+ (Class) platformObjectClass
{
  return [GSAutoLayoutVBox class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [platformObject init];

  /* type */
  {
    var type = [_attributes objectForKey: @"type"];
    if (type != nil)
      {
	/* Default is 'standard' */
	if ([type isEqualToString: @"proportional"])
	  {
	    [platformObject setBoxType: GSAutoLayoutProportionalBox];
	  }
      }
  }
  
  /* Now extract contents.  */
  {
    var i, count = [_content count];

    /* Add contents in REVERSE ORDER.  Library wants them bottom to
     * top, but in the .gsmarkup file they are logically written top
     * to bottom (following the flow of the page).  */
 //   for (i = count - 1; i > -1; i--)
 // obviously not true for capp...
   for (i = 0 ; i < count; i++)
      {
	var v = [_content objectAtIndex: i];
	var view = [v platformObject];

	if (view != nil  &&  [view isKindOfClass: [CPView class]])
	  {
	    [platformObject addView: view];

	    /* Now check attributes of the view: halign, valign,
	     * hborder, vborder, proportion, (, minimumSize?) */

	    /* view->halign */
	    {
	      var halign = [v gsAutoLayoutHAlignment];
	      
	      if (halign != 255)
		{
		  [platformObject setHorizontalAlignment: halign
				   forView: view];
		}
	    }

	    /* view->valign */
	    {
	      var valign = [v gsAutoLayoutVAlignment];
	      
	      if (valign != 255)
		{
		  [platformObject setVerticalAlignment: valign
				   forView: view];
		}
	    }
	    {
	      var attributes = [v attributes];

	      /* view->hborder */
	      {
		var hborder = [attributes valueForKey: @"hborder"];

		/* Try view->border if view->hborder not set.  */
		if (hborder == nil)
		  {
		    hborder = [attributes valueForKey: @"border"];
		  }

		if (hborder != nil)
		  {
		    [platformObject setHorizontalBorder: [hborder intValue]
				     forView: view];
		  }
	      }

	      /* view->vborder */
	      {
		var vborder = [attributes valueForKey: @"vborder"];

		/* Try view->border if view->vborder not set.  */
		if (vborder == nil)
		  {
		    vborder = [attributes valueForKey: @"border"];
		  }

		if (vborder != nil)
		  {
		    [platformObject setVerticalBorder: [vborder intValue]
				     forView: view];
		  }
	      }

	      /* view->proportion */
	      {
		var proportion = [attributes valueForKey: @"proportion"];

		if (proportion != nil)
		  {
		    [platformObject setProportion: [proportion floatValue]
				     forView: view];
		  }
	      }
	    }
	  }
      }

    return platformObject;
  }
}

@end
