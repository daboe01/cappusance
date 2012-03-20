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

@import "GSMarkupTagObject.j"

function hexValueFromUnichars(a, b) 
{
  var result = 0;

  switch (a)
    {
    case '0': result += 0x00; break;
    case '1': result += 0x10; break;
    case '2': result += 0x20; break;
    case '3': result += 0x30; break;
    case '4': result += 0x40; break;
    case '5': result += 0x50; break;
    case '6': result += 0x60; break;
    case '7': result += 0x70; break;
    case '8': result += 0x80; break;
    case '9': result += 0x90; break;
    case 'A': 
    case 'a': result += 0xA0; break;
    case 'B': 
    case 'b': result += 0xB0; break;
    case 'C': 
    case 'c': result += 0xC0; break;
    case 'D':
    case 'd': result += 0xD0; break;
    case 'E': 
    case 'e': result += 0xE0; break;
    case 'F': 
    case 'f': result += 0xF0; break;
    default: return -1;
    }

  switch (b)
    {
    case '0': result += 0x0; break;
    case '1': result += 0x1; break;
    case '2': result += 0x2; break;
    case '3': result += 0x3; break;
    case '4': result += 0x4; break;
    case '5': result += 0x5; break;
    case '6': result += 0x6; break;
    case '7': result += 0x7; break;
    case '8': result += 0x8; break;
    case '9': result += 0x9; break;
    case 'A': 
    case 'a': result += 0xA; break;
    case 'B': 
    case 'b': result += 0xB; break;
    case 'C': 
    case 'c': result += 0xC; break;
    case 'D':
    case 'd': result += 0xD; break;
    case 'E': 
    case 'e': result += 0xE; break;
    case 'F': 
    case 'f': result += 0xF; break;
    default: return -1;
    }

  return (result / 255.);
}

/* The argument type is only used on systems without a working
 * CPInvocation.  */
function getFontWithSelectorSize(selector, type, size)
{
  var ms;
  var i;
  var nsfont = [CPFont class];
  var result;

  ms = [nsfont methodSignatureForSelector: selector];
  i = [CPInvocation invocationWithMethodSignature: ms];
  [i setSelector: selector];
  [i setTarget: nsfont];
  [i setArgument: size  atIndex: 2];
  [i invoke];
  return [i returnValue];
}



@implementation GSMarkupTagObject (TagLibraryAdditions)

- (CPColor) colorValueForAttribute: (CPString)attribute
{
  var value = [_attributes objectForKey: attribute];

  if (value == nil)
    {
      return nil;
    }

  /* Try [CPColor +valueColor].  */
  {
    var name = [CPString stringWithFormat: @"%@Color", value];
    var selector = CPSelectorFromString (name);

    if (selector != NULL  && [CPColor respondsToSelector: selector])
      {
	return [CPColor performSelector: selector];
      }
  }
  
  /* Try RRGGBB or RRGGBBAA format.  */
  if ([value length] == 6  ||  [value length] == 8)
    {
      var r, g, b, a;

      r = hexValueFromUnichars ([value characterAtIndex: 0],
				[value characterAtIndex: 1]);
      if (r == -1)
	{
	  return nil;
	}
      g = hexValueFromUnichars ([value characterAtIndex: 2],
				[value characterAtIndex: 3]);
      if (g == -1)
	{
	  return nil;
	}
      b = hexValueFromUnichars ([value characterAtIndex: 4],
				[value characterAtIndex: 5]);
      if (b == -1)
	{
	  return nil;
	}
      
      if ([value length] == 8)
	{
	  a = hexValueFromUnichars ([value characterAtIndex: 6],
				    [value characterAtIndex: 7]);
	  if (a == -1)
	    {
	      return nil;
	    }
	}
      else
	{
	  a = 1.0;
	}

      return [CPColor colorWithCalibratedRed: r
		      green: g
		      blue: b
		      alpha: a];
    }

  return nil;
}

- (CPFont) fontValueForAttribute: (CPString)attribute
{
  var value = [_attributes objectForKey: attribute];
  var pointSizeChange = 1;
  var pointSizeChanged = NO;
  var selector;
  var type;

  if (value == nil)
    {
      return nil;
    }

  selector = @selector(labelFontOfSize:);
  type = @"label";
  {
    var a = [value componentsSeparatedByString: @" "];
    var i, count = [a count];
    
    for (i = 0; i < count; i++)
      {
	var token = [a objectAtIndex: i];
	var found = NO;

	switch ([token length])
	  {
	  case 3:
	    {
	      if ([token isEqualToString: @"big"])
		{
		  pointSizeChange = 1.25;
		  found = YES;
		}
	      else if ([token isEqualToString: @"Big"])
		{
		  pointSizeChange = 1.5;
		  found = YES;
		}
	      break;
	    }
	  case 4:
	    {
	      if ([token isEqualToString: @"huge"])
		{
		  pointSizeChange = 2;
		  found = YES;
		}
	      else if ([token isEqualToString: @"Huge"])
		{
		  pointSizeChange = 3;
		  found = YES;
		}
	      else if ([token isEqualToString: @"tiny"])
		{
		  pointSizeChange = 0.5;
		  found = YES;
		}
	      else if ([token isEqualToString: @"Tiny"])
		{
		  pointSizeChange = 0.334;
		  found = YES;
		}

	      break;
	    }
	  case 5:
	    {
	      if ([token isEqualToString: @"small"])
		{
		  pointSizeChange = 0.80;
		  found = YES;
		}
	      else if ([token isEqualToString: @"Small"])
		{
		  pointSizeChange = 0.667;
		  found = YES;
		}
	      break;
	    }
	  case 6:
	    {
	      if ([token isEqualToString: @"medium"])
		{
		  pointSizeChange = 1;
		  found = YES;
		}
	      break;
	    }
	  }

	if (found)
	  {
	    pointSizeChanged = YES;
	  }
	

	if (! found)
	  {
	    var name;
	    var s;

	    name = [CPString stringWithFormat: @"%@FontOfSize:", token];
	    s = CPSelectorFromString (name);
	    
	    if (s != NULL  && [CPFont respondsToSelector: s])
	      {
		selector = s;
		type = token;
		found = YES;
	      }
	  }
	if (! found)
	  {
	    var g = [token floatValue];
	    if (g > 0)
	      {
		pointSizeChange = g;
		pointSizeChanged = YES;
	      }
	  }
      }
  }
  
  /* Get the font.  */
  {
    var f;
    
    f = getFontWithSelectorSize (selector, type, 0);

    if (pointSizeChanged)
      {
	var pointSize = [f pointSize];
	
	pointSize = pointSize * pointSizeChange;
	
	f = getFontWithSelectorSize (selector, type, pointSize);
      }

    return f;
  }
  
}

- (int) integerMaskValueForAttribute: (CPString)attribute
	    withMaskValuesDictionary: (CPDictionary)dictionary
{
  var value = [_attributes objectForKey: attribute];
  var integerMask = 0;

  if (value == nil)
    {
      return 0;
    }

  {
    var a = [value componentsSeparatedByString: @"|"];
    var i, count = [a count];
    
    for (i = 0; i < count; i++)
      {
	var token = [a objectAtIndex: i];
	var tokenValue = nil;

	token = [token stringByTrimmingCharactersInSet: 
			 [CPCharacterSet whitespaceAndNewlineCharacterSet]];
	tokenValue = [dictionary objectForKey: token];

	if (tokenValue == nil)
	  {
	    CPLog (@"Warning: <%@> has unknown value '%@' for attribute '%@'.  Ignored.",
		   [[self class] tagName], token, attribute);
	  }
	else
	  {
	    integerMask |= [tokenValue intValue];
	  }
      }
  }

  return integerMask;
}

@end

