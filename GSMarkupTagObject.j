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
@import "GSMarkupAwaker.j"
/*
 * Private method to check that 'aClass' is the same, or a subclass,
 * of 'aPotentialSuperClass'.  Return YES if so, and NO if not.
 */
@implementation CPObject(_IsClassSubclassOfClass)
+(BOOL) isSubclassOfClass:(Class) aPotentialSuperClass
{	var aClass =[self class];
	if (aClass == aPotentialSuperClass)
    {
		return YES;
    }
	else
    {
		while (aClass != Nil)
        {
			aClass = [aClass superclass];
			
			if (aClass == aPotentialSuperClass)
            {
				return YES;
            }
        } 
		return NO;
    }
}
@end

@implementation GSMarkupTagObject: CPObject
{	CPDictionary _attributes;
	CPArray _content;
	id _platformObject;

  /* The following is used, if not nil, to translate localizable
   * strings when creating the platform objects.  */
  id _localizer;

  /* The following is used, if not nil, to record the platformObject
   * the first time that it is created.  The method
   * -(void)recordPlatformObject: of the _awaker must be called when
   * the _platformObject is created.  Later, the decoder will ask the
   * _awaker to awake all platformObjects registered with it.  The
   * _awaker will send a awakeFromGSMarkup message to all registered
   * platformObjects which respond to that message.
   */
  id _awaker;
}

+ (CPString) tagName
{
  return nil;
}

- (id) initWithAttributes: (CPDictionary)attributes
		  content: (CPArray)content
{
  _attributes = attributes;
  _content = content;
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (CPDictionary) attributes
{
  return _attributes;
}

- (CPArray) content
{
  return _content;
}

- (CPArray) localizableStrings
{
  var a = [CPMutableArray array];
  var att;
  var i, count;

  /* First, extract localizable strings from content.  */
  count = [_content count];
  
  for (i = 0; i < count; i++)
    {
      var o = [_content objectAtIndex: i];

      if ([o isKindOfClass: [GSMarkupTagObject class]])
	{
	  var k = [o localizableStrings];
	  if (k != nil)
	    {
	      [a addObjectsFromArray: k];
	    }
	}
      else if ([o isKindOfClass: [CPString class]])
	{
	  [a addObject: o];
	}
    }

  /* Then, extract localizable strings from attributes.  */
  att = [[self class] localizableAttributes];

  count = [att count];
  
  for (i = 0; i < count; i++)
    {
      var attribute = [att objectAtIndex: i];
      var value = [_attributes objectForKey: attribute];
      if (value != nil)
      {
	[a addObject: value];
      }
    }
  
  return a;
}

+ (CPArray) localizableAttributes
{
  return nil;
}

- (void) setAwaker: (GSMarkupAwaker)awaker
{
  var i, count;

  _awaker = awaker;

  count = [_content count];
  
  for (i = 0; i < count; i++)
    {
      var o = [_content objectAtIndex: i];
      
      if ([o isKindOfClass: [GSMarkupTagObject class]])
	{
	  [o setAwaker: awaker];
	}
    }
}

- (void) setPlatformObject: (id)object
{
  if (_platformObject == object)
    {
      return;
    }

  if (_platformObject != nil)
    {
      /* The following will do nothing if _awaker is nil.  */
      [_awaker deregisterObject: _platformObject];
    }

  _platformObject = object;

  if (object != nil)
    {
      /* The following will do nothing if _awaker is nil.  */
      [_awaker registerObject: object];
    }
}

- (id) platformObject
{
  if (!_platformObject)
    {
      /* Build the object.  */
      var platformObject = [self allocPlatformObject];
      platformObject = [self initPlatformObject: platformObject];
      platformObject = [self postInitPlatformObject: platformObject];

      [self setPlatformObject: platformObject];
      }

  /* We own the object we return ... it is released when we are
   * deallocated.  The caller should RETAIN it if it wants it to
   * survive our deallocation.
   */
  return _platformObject;
}

- (id) allocPlatformObject
{
  var selfClass = [self class];
  var poclass = [selfClass platformObjectClass];

  if ([selfClass useInstanceOfAttribute])
    {
      var className = [_attributes objectForKey: @"instanceOf"];
      
      if (className != nil)
	{
	  var nonStandardClass = CPClassFromString (className);
	  
	  if (nonStandardClass != Nil)
	    {
		if ([nonStandardClass isSubclassOfClass:poclass])
		{
		  poclass = nonStandardClass;
		}
	    }
	}
    }

  return [poclass alloc];
}

+ (Class) platformObjectClass
{
  return Nil;
}

+ (BOOL) useInstanceOfAttribute
{
  return NO;
}

- (id) initPlatformObject: (id)platformObject
{
  return [platformObject init];
}

- (id) postInitPlatformObject: (id)platformObject
{
  return platformObject;
}

- (CPString) description
{
  return [CPString stringWithFormat: 
		     @"%@\nvar attributes =%@\nvar content =%@\var platformObject =%@",
		   [super description],
		   [_attributes description],
		   [_content description],
		   [_platformObject description]];
}

- (int) intValueForAttribute: (CPString)attribute
{	return parseInt([_attributes objectForKey:attribute]);
}

- (int) stringValueForAttribute: (CPString)attribute
{	return [_attributes objectForKey:attribute];
}

- (int) boolValueForAttribute: (CPString)attribute
{
  var value = [_attributes objectForKey: attribute];

  if (value == nil)
    {
      return -1;
    }

  switch ([value length])
    {
    case 1:
      {
	var a = [value characterAtIndex: 0];
	switch (a)
	  {
	  case 'y':
	  case 'Y':
	    return 1;

	  case 'n':
	  case 'N':
	    return 0;
	  }

	return -1;
      }
    case 2:
      {
	var a = [value characterAtIndex: 0];
	if (a == 'n'  ||  a == 'N')
	  {
	    var b = [value characterAtIndex: 1];
	    if (b == 'o'  ||  b == 'O')
	      {
		return 0;
	      }
	  }
	
	return -1;
      }
    case 3:
      {
	var a = [value characterAtIndex: 0];
	if (a == 'y'  ||  a == 'Y')
	  {
	    var b = [value characterAtIndex: 1];
	    if (b == 'e'  ||  b == 'E')
	      {
		var c = [value characterAtIndex: 2];
		if (c == 's'  ||  c == 'S')
		  {
		    return 1;
		  }
	      }
	  }

	return -1;
      }
    }

  return -1;
}

- (void) setLocalizer: (GSMarkupLocalizer)localizer
{
  var i, count;

  _localizer = localizer;

  count = [_content count];
  
  for (i = 0; i < count; i++)
    {
      var o = [_content objectAtIndex: i];
      
      if ([o isKindOfClass: [GSMarkupTagObject class]])
	{
	  [o setLocalizer: localizer];
	}
    }
}

- (CPString) localizedStringValueForAttribute: (CPString)attribute
{
  var value = [_attributes objectForKey: attribute];

  if (value == nil)
    {
      return nil;
    }
  else
    {
return value;	//<!>
     return [_localizer localizeString: value];
    }
}

@end

