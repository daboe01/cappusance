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


@implementation GSMarkupBoxContentView: CPView

- (CPView)firstSubview
{
  var subviews = [self subviews];

  if (subviews != nil  &&  [subviews count] > 0)
    {
      return [subviews objectAtIndex: 0];  
    }
  else
    {
      return nil;
    }
}

/* This is only used when setting up the thing at startup, and never
 * afterwards.  */
- (void) sizeToFit
{
  var firstSubview = [self firstSubview];

  [self setAutoresizesSubviews: NO];
  if (firstSubview)
    {	[self setFrameSize: [firstSubview frame].size];
    }
  else
    {

      [self setFrameSize: CPMakeSize (50, 50)];
    }

  [self setAutoresizesSubviews: YES];
}

/* Use the autolayout defaults of the first subview.  */
- (GSAutoLayoutAlignment) autolayoutDefaultVerticalAlignment
{
  var firstSubview = [self firstSubview];

  if (firstSubview)
    {
      return [firstSubview autolayoutDefaultVerticalAlignment];
    }
  else
    {
      return [super autolayoutDefaultVerticalAlignment];
    }
}

- (GSAutoLayoutAlignment) autolayoutDefaultHorizontalAlignment
{
  var firstSubview = [self firstSubview];

  if (firstSubview)
    {
      return [firstSubview autolayoutDefaultHorizontalAlignment];
    }
  else
    {
      return [super autolayoutDefaultHorizontalAlignment];
    }
}

@end

@implementation GSMarkupTagBox:GSMarkupTagView

+ (CPString) tagName
{
  return @"box";
}

+ (Class) platformObjectClass
{
  return [CPBox class];
}

/* Basically, we only recognize the following options -
 *
 * title (yes / no); if yes, it is always on top
 * border (yes / no); if yes, the platform default border is always used.
 */
- (id) initPlatformObject: (id)platformObject
{
  platformObject = [platformObject init];

  /* title */
  {
    var title = [self localizedStringValueForAttribute: @"title"];

    if (title == nil)
      {
      }
    else
      {
	  [platformObject setTitlePosition: CPAtTop];
	 [platformObject setTitle: title];
      }
  }

  /* no border - FIXME tag attribute name */
  {
    if ([self boolValueForAttribute: @"hasBorder"] == 0)
      {
	[platformObject setBorderType: CPNoBorder];
      }
  }

  /* Content view.  */
  if (_content != nil  &&  [_content count] > 0)
    {
      var subview = [[_content objectAtIndex: 0] 
					  platformObject];
      if ([subview isKindOfClass: [CPView class]])
	{
		var v= [GSMarkupBoxContentView new];
		[v addSubview: subview];
		[v sizeToFit];
		[platformObject setContentView: v];
	}
    }

  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

/*
 * CPBox is special because it's a container outside our control :-(
 *
 * Standard boxes/containers under our control keep track of the
 * autolayout flags of the views they enclose, and can compute their
 * own autolayout flags (used by other boxes/containers enclosing
 * them) from those.  When they are added to an enclosing window /
 * box, the autolayout flags they compute are used.
 *
 * CPBox can not keep track of the autolayout flags of the view it
 * encloses, but we still want to fake the correct behaviour, so that
 * for example if you put something which expands in an CPBox, the
 * CPBox will expand; if you put something which does not expand, the
 * CPBox will not expand.
 *
 * In practice, if you put an CPBox in a container, the CPBox will
 * first be asked to compute default autolayout flags.  That requests
 * is managed by CPBox's default autolayout stuff, and by our
 * GSMarkupBoxContentView class above; it will compute correct
 * autolayout flags unless the CPBox, or its content, have manual
 * hardcoded hexpand/vexpand flags set.
 *
 * The library still gives us a chance to manage that case by calling
 * the following method asking if manual flags are set.  In that case,
 * we examine the CPBox's manually hardcoded flags (like super does),
 * and then the content's manually hardcoded flags if any.
 */
- (int) gsAutoLayoutVAlignment
{
  /* If an align flag was manually specified by the user, return it.  */
  var flag = [super gsAutoLayoutVAlignment];
  
  if (flag != 255)
    {
      return flag;
    }

  /* Else, check if the content has a flag which was manually
   * specified by the user.  If so, that should override the default
   * computations. */
  {
    var view = [_content objectAtIndex: 0];
    
    if ([view isKindOfClass: [GSMarkupTagView class]])
      {
	flag = [view gsAutoLayoutVAlignment];

	if (flag != 255)
	  {
	    if (flag == GSAutoLayoutExpand  ||  flag == GSAutoLayoutWeakExpand)
	      {
		return flag;
	      }
	    else
	      {
		/* If the content does not expand, we center ourselves
		 * by default.  */
		return GSAutoLayoutAlignCenter;
	      }
	  }
      }
  }
  
  /* Else, return 255.  That will cause the autolayout default to be
   * used.  
   */
  return 255;
}

- (int) gsAutoLayoutHAlignment
{
  /* If an align flag was manually specified by the user, return it.  */
  var flag = [super gsAutoLayoutHAlignment];
  
  if (flag != 255)
    {
      return flag;
    }

  /* Else, check if the content has a flag which was manually
   * specified by the user.  If so, that should override the default
   * computations. */
  {
    var view = [_content objectAtIndex: 0];
    
    if ([view isKindOfClass: [GSMarkupTagView class]])
      {
	flag = [view gsAutoLayoutHAlignment];

	if (flag != 255)
	  {
	    if (flag == GSAutoLayoutExpand  ||  flag == GSAutoLayoutWeakExpand)
	      {
		return flag;
	      }
	    else
	      {
		/* If the content does not expand, we center ourselves
		 * by default.  */
		return GSAutoLayoutAlignCenter;
	      }
	  }
      }
  }
  
  /* Else, return 255.  That will cause the autolayout default to be
   * used.  */
  return 255;
}


@end
