/* -*-objc-*-
   GSMarkupTagImage.m

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: January 2003

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

@import <AppKit/CPImageView.j>
@import "GSMarkupTagControl.j"

@implementation CPImageViewProp:CPImageView

-(void) setObjectValue: someImg
{	var size=[someImg size];
	if(size) [self setBounds: CPMakeRect(0,0, size.width, size.height)];
	[super setObjectValue:someImg];
}

@end


@implementation GSMarkupTagImage: GSMarkupTagControl
+ (CPString) tagName
{
  return @"image";
}

+ (Class) platformObjectClass
{
  return [CPImageViewProp class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];

  /* On GNUstep, it seems image views are by default editable.  Turn
   * that off, we want uneditable images by default.
   */
  [platformObject setEditable: NO];	

  /* editable */
  {
    var editable = [self boolValueForAttribute: @"editable"];
    
    if (editable == 1)
      {
	[platformObject setEditable: YES];
      }
    else if (editable == 0)
      {
	[platformObject setEditable: NO];
      }
  }

  /* name */
  {
    var name = [_attributes objectForKey: @"name"];

    if (name != nil)
      {
	[platformObject setImage: [CPImage imageNamed: name]];
      }
  }
  /* file */
  {
    var name = [_attributes objectForKey: @"ressource"];

    if (name != nil)
      {
	[platformObject setImage: [[CPImage alloc] initWithContentsOfFile: [CPString stringWithFormat:@"%@/%@", [[CPBundle mainBundle] resourcePath],name ]] ];
      }
  }

  /* scaling */
  {
    var scaling = [_attributes objectForKey: @"scaling"];
   
    if (scaling != nil  &&  [scaling length] > 0)
      {
	
	switch ([scaling characterAtIndex: 0])
	  {
	  case 'n':
	    if ([scaling isEqualToString: @"none"])
	      {
		[platformObject setImageScaling: CPScaleNone];
	      }
	    break;
	  case 'p':
	    if ([scaling isEqualToString: @"proportionally"])
	      {
		[platformObject setImageScaling: CPScaleProportionally];
	      }
	    break;
	  case 't':
	    if ([scaling isEqualToString: @"toFit"])
	      {
		[platformObject setImageScaling: CPScaleToFit];
	      }
	    break;
	  }
      }
  }

  /* imageAlignment */
  {
    var alignment = [_attributes objectForKey: @"imageAlignment"];
   
    /* Backwards-compatible check introduced on 27 Feb 2008, will be
     * removed on 27 Feb 2009.
     */
    if (alignment == nil)
      {
	/* Check for the old name "alignment"  */
	alignment = [_attributes objectForKey: @"alignment"];

	if (alignment != nil)
	  {
	    CPLog (@"The 'alignment' attribute has been renamed to 'imageAlignment'.  Please update your gsmarkup files");
	  }
      }

    if (alignment != nil  &&  [alignment length] > 0)
      {
	
	switch ([alignment characterAtIndex: 0])
	  {
	  case 'b':
	    if ([alignment isEqualToString: @"bottom"])
	      {
		[platformObject setImageAlignment: CPImageAlignBottom];
	      }
	    else if ([alignment isEqualToString: @"bottomLeft"])
	      {
		[platformObject setImageAlignment: CPImageAlignBottomLeft];
	      }
	    else if ([alignment isEqualToString: @"bottomRight"])
	      {
		[platformObject setImageAlignment: CPImageAlignBottomRight];
	      }
	    break;

	  case 'c':
	    if ([alignment isEqualToString: @"center"])
	      {
		[platformObject setImageAlignment: CPImageAlignCenter];
	      }
	    break;

	  case 'l':
	    if ([alignment isEqualToString: @"left"])
	      {
		[platformObject setImageAlignment: CPImageAlignLeft];
	      }
	    break;

	  case 'r':
	    if ([alignment isEqualToString: @"right"])
	      {
		[platformObject setImageAlignment: CPImageAlignRight];
	      }
	    break;

	  case 't':
	    if ([alignment isEqualToString: @"top"])
	      {
		[platformObject setImageAlignment: CPImageAlignTop];
	      }
	    else if ([alignment isEqualToString: @"topLeft"])
	      {
		[platformObject setImageAlignment: CPImageAlignTopLeft];
	      }
	    else if ([alignment isEqualToString: @"topRight"])
	      {
		[platformObject setImageAlignment: CPImageAlignTopRight];
	      }
	    break;
	  }
      }
  }

  
	var height;
	height = [_attributes objectForKey: @"height"];
	if (height == nil)
	{
		[_attributes setObject: @"100" forKey: @"height"];
	}
	var width;
	width = [_attributes objectForKey: @"width"];
	if (width == nil)
    {	[_attributes setObject: @"100" forKey: @"width"];
    }

  return platformObject;
}

@end
