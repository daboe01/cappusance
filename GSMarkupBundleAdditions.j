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

@import <Foundation/CPBundle.j>
@import "GSMarkupDecoder.j"
@import "GSMarkupAwaker.j"
@import "GSMarkupLocalizer.j"
@import "GSMarkupConnector.j"

GSMarkupBundleDidLoadGSMarkupNotification= @"GSMarkupBundleDidLoadGSMarkupNotification";


var staticNameTable;

@implementation CPBundle (GSMarkupBundleStaticObjects)
- (CPString)localizedStringForKey:(CPString )key value:(CPString)value table:(CPString)tableName
{	if(!key || !tableName) return value;
	return key;
}

+ (void) registerStaticObject: (id)object
		     withName: (CPString)itsId
{
  if (staticNameTable == nil)
    {
      staticNameTable = [CPMutableDictionary new];
    }

  [staticNameTable setObject: object  forKey: itsId];
}

+ (id)    loadGSMarkupData: (CPData)data
	   externalNameTable: (CPDictionary)context
     localizableStringsTable: (CPString)table
		    inBundle: (CPBundle)bundle
		tagMapping: (CPDictionary)mapping;

{

	[self registerStaticObject: [CPApplication sharedApplication]  withName: @"CPApp"];

	var success = NO;

	if (data == nil)
    {
		return NO;
    }

	/* If bundle is specified, use it; otherwise, use mainBundle.  */
	if (bundle == nil)
    {
		bundle = [CPBundle mainBundle];
    }
	var nameTable;
	var outputTable;
	var connectors;
	var platformObjects;
	var i, count;
	var e;
	var key;
	var topLevelObjects = nil;
	var awaker = [GSMarkupAwaker new];
	var decoder=[[GSMarkupDecoder alloc] initWithXMLString: [data rawString]];
	[decoder setExternalNameTable:context];
	[decoder parse];
	var objects=[decoder objects];

	if (mapping != nil)
	{	e = [mapping keyEnumerator];
	    while ((key = [e nextObject]) != nil)
		{	var value = [mapping objectForKey: key];
	        [decoder setObjectClass: value  forTagName: key];
		}
	}
	platformObjects = [CPMutableArray arrayWithCapacity: [objects count]];
	var localizer = [[GSMarkupLocalizer alloc] initWithTable: table
					       bundle: bundle];
	nameTable = [[decoder nameTable] mutableCopy];
	connectors = [decoder connectors];

	count = [objects count];
	for (i = 0; i < count; i++)
	{	var o;
	    var platformObject;
	    
	    o = [objects objectAtIndex: i];
	    [o setLocalizer: localizer];
	    [o setAwaker: awaker];

	    /* platformObject is autoreleased.  */
	    platformObject = [o platformObject];

	    if (platformObject != nil)
	      {
		[platformObjects addObject: platformObject];
	      }
	  }
      /* Now update the nameTable replacing each decoded object with
       * its platformObject in the nameTable.
       */
      /* Note that we can not use [nameTable keyEnumerator] because we
       * will be modifying the nameTable dictionary.  So we first get
       * an array with all the keys, then we enumerate that one.
       */
	e = [[nameTable allKeys] objectEnumerator];
	while ((key = [e nextObject]) != nil)
	{
		var object = [nameTable objectForKey: key];
		var platformObject = [object platformObject];
		if (platformObject != nil)
	    {	[nameTable setObject: platformObject  forKey: key];
	    }
		else
	    {
			[nameTable removeObjectForKey: key];
	    }
	}

      /* Now extend the nameTable by adding the externalNameTable
       * (which contains references to object outside the GSMarkup
       * file).  */
	e = [context keyEnumerator];
	while ((key = [e nextObject]) != nil)
	{	var object = [context objectForKey: key];
	  
	  /* CPTopLevelObjects is special ... if it exists, it is a
	   * key to a mutable array where we store the top-level
	   * objects so that the caller can access them.  Inspired by
	   * an undocumented feature of nib loading on other
	   * platforms.  */
		if ([key isEqualToString: @"CPTopLevelObjects"]
	      && [object isKindOfClass: [CPMutableArray class]])
	    {
			topLevelObjects = object;
	    }
		else
	    {
	      [nameTable setObject: object  forKey: key];
	    }
	}

      /* Now extend the nameTable adding the static objects (for example,
       * NSApp if it's a gui application).
       */
	if (staticNameTable != nil)
	{	[nameTable addEntriesFromDictionary: staticNameTable];
	}

      /* Now establish the connectors.  Our connectors can manage
       * the nameTable automatically.  */
	count = [connectors count];
	for (i = 0; i < count; i++)
	{	var connector = [connectors objectAtIndex: i];
//alert([connector description]);
		[connector establishConnectionUsingNameTable: nameTable];
	}

      /* Register the NSOwner, if any, in the list of objects to
       * awake.  */
	{
		var fileOwner = [nameTable objectForKey: @"CPOwner"];
		if (fileOwner != nil)
		{
			[awaker registerObject: fileOwner];
		}
	}

      /* Now awake the objects.  */
	[awaker awakeObjects];

      /* Done - finally send the notification that we loaded the
       * file.  */


	var fileOwner = [nameTable objectForKey: @"CPOwner"];
	var objects = [CPMutableArray array];
	var n;

	/* Build the array of top-level objects for the
	 * notification.  */
	count = [platformObjects count];
	for (i = 0; i < count; i++)
	  {
	    var object = [platformObjects objectAtIndex: i];
	    [objects addObject: object];
	  }
	
	/* Create the notification.  */
	n = [CPNotification 
	      notificationWithName: GSMarkupBundleDidLoadGSMarkupNotification
	      object: fileOwner
	      userInfo: [CPDictionary dictionaryWithObject: objects
				      forKey: @"CPTopLevelObjects"]];

	/* Send the notification to the file owner manually.  */
	if (fileOwner != nil)
	  {
	    if ([fileOwner respondsToSelector: 
			     @selector (bundleDidLoadGSMarkup:)])	      
	      {
			[fileOwner bundleDidLoadGSMarkup: n];
	      }
	  }
	
	[[CPNotificationCenter defaultCenter] postNotification: n];

	if (topLevelObjects != nil)
	{
	  count = [platformObjects count];
	  for (i = 0; i < count; i++)
	    {
	      var object = [platformObjects objectAtIndex: i];
	      [topLevelObjects addObject: object];
	    }
	}

      /*
       * Finally, pass back name table contents in the context if possible.
       */
      outputTable = [context objectForKey: @"GSMarkupNameTable"];
      if (outputTable != nil
		&& [outputTable isKindOfClass: [CPMutableDictionary class]] == YES)
	{
	  var k;

	  [outputTable removeAllObjects];
	  e = [nameTable keyEnumerator];
	  while ((k = [e nextObject]) != nil)
	    {
	      if ([context objectForKey: k] == nil)
			{
				[outputTable setObject: [nameTable objectForKey: k]
				  forKey: k];
			}
	    }
	}

	success = YES;
	return success? decoder:nil;
}


// convenience method
+ (id) loadRessourceNamed: (CPString) fileName owner:(id) anOwner
{	var	configData=[[CPData alloc]
		initWithContentsOfURL: [CPURL URLWithString:[CPString stringWithFormat:@"%@/%@", [[CPBundle mainBundle] resourcePath], fileName ]]];

	return [CPBundle loadGSMarkupData: configData externalNameTable: [CPDictionary dictionaryWithObject: anOwner forKey:"CPOwner"]
			localizableStringsTable: nil inBundle: nil tagMapping: nil];
}


@end
