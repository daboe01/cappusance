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
  return [FSPopUpButton class];
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
	var peek;
	if(peek=[self stringValueForAttribute:  "itemsPredicate"])
	{	[platformObject setItemsPredicateTemplate: peek];
	}
	if(peek=[self stringValueForAttribute:  "filterKeyPath"])
	{	[platformObject setItemsFilterKeyPath: peek];
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


@implementation FSPopUpButton:CPPopUpButton
{	id _itemsPredicateTemplate @accessors(property=itemsPredicateTemplate);
	id _itemsFilterKeyPath @accessors(property= itemsFilterKeyPath);
}
- (id)initWithCoder:(id)aCoder
{
    self=[super initWithCoder:aCoder];
    if (self != nil)
    {
        [self setItemsPredicateTemplate:[aCoder decodeObjectForKey:"ItemsPredicateTemplate"]];
        [self setItemsFilterKeyPath:[aCoder decodeObjectForKey:"ItemsFilterKeyPath"]];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject: _itemsPredicateTemplate forKey: "ItemsPredicateTemplate"];
    [aCoder encodeObject: _itemsFilterKeyPath forKey: "ItemsFilterKeyPath"];
}

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
// itemArray part of standard API
-(void)setItemArray:(CPArray) someArray
{
	var binding= [CPBinder getBinding:"itemArray" forObject: self];
	if(binding)
	{	var bindingInfo = binding._info;
		var destination = [bindingInfo objectForKey:CPObservedObjectKey];
//alert(destination)
	}

	var myCurrentArr=[self itemArray];
	[self _consolidateItemArrayLengthToArray: someArray];
	var  j, l1 = someArray.length;
	for (j = 0; j < l1; j++)
	{	[myCurrentArr[j] setTitle: someArray[j]];
//setRepresentedObject:
	}
	[self synchronizeTitleAndSelectedItem];
}

-(CPArray)tagArray
{	return [];	//<!> fixme
}
-(void)setTagArray:(CPArray) someArray
{	var myCurrentArr=[self itemArray];
	[self _consolidateItemArrayLengthToArray: someArray];
	var  j, l1 = someArray.length;
	for (j = 0; j < l1; j++)
	{	[myCurrentArr[j] setTag: someArray[j]];
	}
}

// i have no idea, why we need this in case of selectedTag bindings
-(void) setSelectedTag:(int) someValue
{
	[self selectItemWithTag: someValue];
}
-(int) selectedTag
{	return [[self selectedItem] tag];
}

@end

