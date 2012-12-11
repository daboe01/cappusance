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

@import <Foundation/CPObject.j>

@implementation GSMarkupConnector:CPObject

- (id) initWithAttributes: (CPDictionary)attributes
		  content: (CPArray)content
{
  return self;
}

- (CPDictionary) attributes
{
  return [CPDictionary dictionary];
}

- (CPArray) content
{
  return nil;
}

+ (CPString) tagName
{
  return nil;
}

- (void) establishConnectionUsingNameTable: (CPDictionary)nameTable
{
  /* Subclass responsibility ! */
}

+ (id) getObjectForIdString: (CPString)idString
	     usingNameTable: (CPDictionary)nameTable
{
  var r = [idString rangeOfString: @"."];

  if (r.location == CPNotFound)
    {
      /* If there is no '.' in the idString, just look the string up
       * in the name table, and return the result.  */
      return [nameTable objectForKey: idString];
    }
  else
    {
      /* Else, the string up to the first '.' is the object name to
       * look up in the name table, while everything after the first
       * '.' is a key-value path.
       */
      var objectName = [idString substringToIndex: r.location];
      var keyValuePath = [idString substringFromIndex: CPMaxRange(r)];
      
      /* Extract the object with that name.  */
      var object = [nameTable objectForKey: objectName];
      
      /* Apply the specified key-value coding path.  */
      return [object valueForKeyPath: keyValuePath];
      
    }
}

+ (id) getPlatformObjectForIdString: (CPString)idString
	     usingNameTable: (CPDictionary)nameTable
{	var r = [idString rangeOfString: @"."];

	if (r.location == CPNotFound)
	{
		return [[nameTable objectForKey: idString] platformObject];
	}
	else
	{	var objectName = [idString substringToIndex: r.location];
		var keyValuePath = [idString substringFromIndex: CPMaxRange(r)];
      
		var object = [[nameTable objectForKey: objectName] platformObject];
		return [object valueForKeyPath: keyValuePath];
    }
}

@end

@implementation GSMarkupOneToOneConnector: GSMarkupConnector
{	CPString _source;
	CPString _target;
	CPString _label;
}

- (id) initWithSource: (CPString)source
	       target: (CPString)target
		label: (CPString)label
{	/* Remove the # from the beginning of source and target if any.  */
  if ([source hasPrefix: @"#"])
    {
      source = [source substringFromIndex: 1];
    }
  _source = source;

  if ([target hasPrefix: @"#"])
    {
      target = [target substringFromIndex: 1];
    }
  _target = target;

  _label = label;

  return self;
}

- (id) initWithAttributes: (CPDictionary)attributes
		  content: (CPArray)content
{
  return [self initWithSource: [attributes objectForKey: @"source"]
	       target: [attributes objectForKey: @"target"]
	       label: [attributes objectForKey: @"label"]];
}

- (CPDictionary) attributes
{
  var d;
  var source;
  var target;

  /* Add # in front of source and target.  */
  source = [CPString stringWithFormat: @"#%@", _source];
  target = [CPString stringWithFormat: @"#%@", _target];
  
  d = [CPDictionary dictionaryWithObjectsAndKeys: source, @"source",
		    target, @"target", _label, @"label", nil];
  return d;
}

- (CPArray) content
{
  return nil;
}

- (void) setSource: (CPString)source
{
  _source = source;
}

- (CPString) source
{
  return _source;
}

- (void) setTarget: (CPString)target
{
  _target = target;
}

- (CPString) target
{
  return _target;
}

- (void) setLabel: (CPString)label
{
  _label = label;
}

- (CPString) label
{
  return _label;
}

- (CPString) description
{
  return [CPString stringWithFormat: @"<%@ source=\"%@\" target=\"%@\" label=\"%@\">",
		   CPStringFromClass ([self class]),
		   _source, _target, _label];
}

@end

@implementation GSMarkupControlConnector: GSMarkupOneToOneConnector

+ (CPString) tagName
{
  return @"control";
}

- (id) initWithAttributes: (CPDictionary)attributes
		  content: (CPArray)content
{
  var label;

  /* Recognize action as preferred to label.  */
  label = [attributes objectForKey: @"action"];
  if (label == nil)
    {
      label = [attributes objectForKey: @"label"];
    }    

  return [self initWithSource: [attributes objectForKey: @"source"]
	       target: [attributes objectForKey: @"target"]
	       label: label];
}

/* var action ="selectAll:" rather var label ="selectAll:"  */
- (CPDictionary) attributes
{
  var d;
  var source;
  var target;

  /* Add # in front of source and target.  */
  source = [CPString stringWithFormat: @"#%@", _source];
  target = [CPString stringWithFormat: @"#%@", _target];
  
  d = [CPDictionary dictionaryWithObjectsAndKeys: source, @"source",
		    target, @"target", _label, @"action", nil];
  return d;
}

- (void) establishConnectionUsingNameTable: (CPDictionary)nameTable
{
  var action = CPSelectorFromString (_label);
  var source = [GSMarkupConnector getObjectForIdString: _source  
				 usingNameTable: nameTable];
  var target = [GSMarkupConnector getObjectForIdString: _target
				 usingNameTable: nameTable];
  [source setAction: action];
  [source setTarget: target];
}
@end

@implementation GSMarkupOutletConnector: GSMarkupOneToOneConnector

+ (CPString) tagName
{
  return @"outlet";
}

- (id) initWithAttributes: (CPDictionary)attributes
		  content: (CPArray)content
{
  var label;
  
  /* Recognize key as preferred to label.  */
  label = [attributes objectForKey: @"key"];
  if (label == nil)
    {
      label = [attributes objectForKey: @"label"];
    }

  return [self initWithSource: [attributes objectForKey: @"source"]
	       target: [attributes objectForKey: @"target"]
	       label: label];
}

- (void) establishConnectionUsingNameTable: (CPDictionary)nameTable;
{
  var source = [GSMarkupConnector getObjectForIdString: _source 
				 usingNameTable: nameTable];
  var target = [GSMarkupConnector getObjectForIdString: _target
				 usingNameTable: nameTable];
//alert("connecting  "+source+" "+target+"  "+ _target+" "+_label);
  [source setValue: target  forKey: [_label substringFromIndex: [_label characterAtIndex:0]=='#'?1:0]];
}

@end


@implementation GSMarkupBindingConnector: GSMarkupOneToOneConnector
{	CPString _entityName;
}

+ (CPString) tagName
{
  return @"binding";
}

- (id) initWithAttributes: (CPDictionary)attributes
		  content: (CPArray)content
{	var o=[self initWithSource: [attributes objectForKey: @"source"]
	       target: [attributes objectForKey: @"target"]
	       label: [attributes objectForKey: @"label"]];
	_entityName=[attributes objectForKey: @"entity"];
	return o;
}

- (void) establishConnectionUsingNameTable: (CPDictionary)nameTable;
{	var source = [GSMarkupConnector getObjectForIdString: _source 
				 usingNameTable: nameTable];
	var target = [GSMarkupConnector getObjectForIdString: _target
				 usingNameTable: nameTable];

	if([source isKindOfClass: [CPTableView class]] && [target isKindOfClass: [CPArrayController class]])
	{
	}
	[source bind: CPValueBinding toObject: target withKeyPath:_label options:nil];
}

@end
