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

@import "GSMarkupTagControl.j"
@import "GSMarkupTagPopUpButtonItem.j"
@import <AppKit/CPPopUpButton.j>

@implementation GSMarkupTagPopUpButton: GSMarkupTagControl
+ (CPString) tagName
{
  return @"popUpButton";
}

+ (Class) platformObjectClass
{
  return [CPPopUpButton class];
}

- (id) initPlatformObject: (id)platformObject
{
  platformObject = [super initPlatformObject: platformObject];
  
  /* title */
  {
    var title = [self localizedStringValueForAttribute: @"title"];
  
    if (title != nil)
      {
	[platformObject setTitle: title];
      }
  }

  /* Create content.  */
  {
    var i, count = [_content count];
    
    for (i = 0; i < count; i++)
      {
	var item = [_content objectAtIndex: i];
	var title = [item localizedStringValueForAttribute: @"title"];
	
	if (title == nil)
	  {
	    title = @"";
	  }

	[platformObject addItemWithTitle: title];

	/* Now get the item we have just added ... it's the last one,
	 * and set it as the platform object of the item.  */
	{
	  var platformItem = [platformObject lastItem];

	  /* The following call will cause the item to load all
	   * additional attributes into the init platform object.  */

	  platformItem = [item initPlatformObject: platformItem];
	  [item setPlatformObject: platformItem];
	}
      }
  }
  
  /* pullsDown */
  {
    var pullsDown = [self boolValueForAttribute: @"pullsDown"];
    
    if (pullsDown == 1)
      {
	[platformObject setPullsDown: YES];
      }
    else if (pullsDown == 0)
      {
	[platformObject setPullsDown: NO];
      }
  }

  /* autoenablesItems */
  {
    var autoenablesItems = [self boolValueForAttribute: @"autoenablesItems"];
    if (autoenablesItems == 0)
      {
	[platformObject setAutoenablesItems: NO];
      }
  }

  return platformObject;
}

+ (CPArray) localizableAttributes
{
  return [CPArray arrayWithObject: @"title"];
}

@end


@implementation CPPopUpButton(KVK4Items)


-(void) _consolidateItemArrayLengthToArray:(CPArray) someArray
{	var myCurrentArr=[self itemArray];
	var l=myCurrentArr.length;
	var l1 = someArray.length;
	var j;
	if(l==l1) return;	// length  is identical: nothing to do
	else if(l<l1)	// new array is larger->append appropriate amount of items at the end
	{	for(j=0;j<(l1-l);j++)
		{	[self addItemWithTitle:""];
		}
	} else			// new array is smaller->remove appropriate amount of items from the end
	{	var removingIndex=l1;	// last item should be preserved
		for(j=0;j<(l-l1);j++)
		{	[self removeItemAtIndex: removingIndex];
		}
	}

}
-(void) setIntegerValue:(int) someValue
{
	[self selectItemWithTag: someValue];
}
-(int) integerValue
{	return [[self selectedItem] tag];
}

- (void)_reverseSetBinding
{	var binderClass = [[self class] _binderClassForBinding: "integerValue"],
        theBinding = [binderClass getBinding:"integerValue" forObject:self];
    [theBinding reverseSetValueFor:@"integerValue"];
}

// itemArray part of standard API
-(void)setItemArray:(CPArray) someArray
{
	var myCurrentArr=[self itemArray];
	[self _consolidateItemArrayLengthToArray: someArray];
	var  j, l1 = someArray.length;
	for (j = 0; j < l1; j++)
	{	[myCurrentArr[j] setTitle: someArray[j]];
	}
	[self synchronizeTitleAndSelectedItem];
}

-(CPArray)tagArray
{	return [];
}
-(void)setTagArray:(CPArray) someArray
{
	var myCurrentArr=[self itemArray];
	[self _consolidateItemArrayLengthToArray: someArray];
	var  j, l1 = someArray.length;
	for (j = 0; j < l1; j++)
	{	[myCurrentArr[j] setTag: someArray[j]];
	}

}


@end

