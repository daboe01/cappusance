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

-(void) _consolidateItemArrayLengthToArray:(CPArray) someArray
{	var myCurrentArr=[self itemArray];
	var l=myCurrentArr.length;
	var l1 = someArray.length;
	var j;
	if(l==l1) return;	// length  is identical: nothing to do
	else if(l<l1)	// new array is larger->append appropriate amount of items at the end
	{	for(j=0;j < (l1 - l); j++)
		{	[self addItemWithTitle:""];
		}
	} else			// new array is smaller->remove appropriate amount of items from the end
	{	var removingIndex=l1;	// last item should be preserved
		for(j = 0; j < (l - l1); j++)
		{	[self removeItemAtIndex: removingIndex];
		}
	}

}
// itemArray part of standard API
-(void)setItemArray:(CPArray) someArray
{	var info=[CPBinder infoForBinding: "itemArray" forObject: self];
	var tagArray;
	if(info)	// this stuff is to allow row-wise filtered popup-lists in table-views
	{	var options= [info objectForKey:CPOptionsKey];
		var predf=[options objectForKey:"PredicateFormat"];
		var owner=[options objectForKey:"Owner"];
		var ac=   [info objectForKey: CPObservedObjectKey];
		var mykey=[info objectForKey: CPObservedKeyPathKey];
		var dotIndex = mykey.lastIndexOf("."),
		mykey=[mykey substringFromIndex: dotIndex+1];
		var myvalkey=[options objectForKey: "valueFace"];
		if(myvalkey)
		{	dotIndex = myvalkey.lastIndexOf("."),
			myvalkey=[myvalkey substringFromIndex: dotIndex+1];
		}
		var sourceArray=[ac arrangedObjects];
		if(predf)
		{	var rhkey;
			var re = new RegExp("\\$([a-zA-Z0-9_]+)");
			var m = re.exec(predf);
			if(m) rhkey =m[1];
			var filterValue;

			if (rhkey) filterValue= [owner isKindOfClass:[CPString class]]? owner: [owner valueForKeyPath: rhkey];
			var mypred = [CPPredicate predicateWithFormat: predf ];
			if(filterValue) mypred = [mypred predicateWithSubstitutionVariables:@{rhkey: filterValue} ];
			sourceArray =[sourceArray filteredArrayUsingPredicate: mypred];
		}
		someArray=[];
		tagArray =[];

		var  i, l = [sourceArray count];
		for (i = 0; i < l; i++)
		{	var curr_obj= [sourceArray objectAtIndex:i];
			someArray.push([curr_obj valueForKey: mykey]);
			if(myvalkey) tagArray.push([curr_obj valueForKey:myvalkey]);
		}
	}
	[self _consolidateItemArrayLengthToArray: someArray];
	var myCurrentArr=[self itemArray];
	var  j, l1 = someArray.length;

	for (j = 0; j < l1; j++)
	{	[myCurrentArr[j] setTitle: someArray[j]];
		if(tagArray) [myCurrentArr[j] setTag: tagArray[j]];
	}

	[self selectItemWithTag:_value];
}

-(void) selectItemWithTag:(int) someValue
{	_value = someValue;
	[super selectItemWithTag:_value];
}

-(int) selectedTag
{	return [[self selectedItem] tag];
}
-(void) setSelectedTag:(id)aTag
{
    [self selectItemWithTag:aTag];
}

@end

