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
@import "GSMarkupConnector.j"


@implementation CPString (CapitalizedString)
- (CPString) stringByUppercasingFirstCharacter
{
  var length = [self length];

  if (length < 1)
	{
	  return self;
	}
  else
	{
	  var s;
	  /* Get the first character.  */
	  var c = [self characterAtIndex: 0];

	  /* If it's not lowercase ... */
	  if (c < 'a'  ||  c > 'z')
	{
	  /* then no need to uppercase.  */
	  return self;
	}
	  
	  /* Else, uppercase the first character.  */
	  c = c.toUpperCase();
	  
	  s = [CPString stringWithString:c];
	  
	  if (length == 1)
	{
	  return s;
	}
	  else
	{
	  return [s stringByAppendingString: [self substringFromIndex: 1]];
	}
	}
}
- (CPString) trimmedString
{	var t=self.replace(/^\s+|\s+$/g,"");
	if(!t) return @"";
	return [CPString stringWithString: t];
}

@end

@implementation CPData(FileLoading)

- (id)initWithContentsOfURL:(CPURL)aURL
{	var plist = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:aURL] returningResponse:nil error:nil];
	if (plist == nil)
	{
		return nil;
	}
	return plist;
}

- (id)initWithContentsOfFile:(CPString)aPath
{	return [self initWithContentsOfURL:[CPURL URLWithString:aPath]];
}
@end

@implementation GSMarkupDecoder: CPObject
{	var _uniqueID;
	CPMutableDictionary _nameTable, _tagNameToObjectClass;
	CPString _xmlStr;
	CPMutableArray _objects, _connectors;
}
+ (id) decoderWithContentsOfFile: (CPString)file
{
   return [[self alloc] initWithContentsOfFile: file];
}

- (id) initWithContentsOfFile: (CPString)file
{
  var d = [[CPData alloc] initWithContentsOfFile: file];

  return [self initWithData: d];
}
- (id) initWithData: someXMLData
{	return [self initWithXMLString: [someXMLData rawString]];
}

- (Class) objectClassForTagName: (CPString)tagName mappedByFormatArray: arr
{	var capitalizedTagName;
	var className;
	var c;
	capitalizedTagName = [tagName stringByUppercasingFirstCharacter];

	className = [_tagNameToObjectClass objectForKey: tagName];
	if (className != nil) [arr insertObject:className atIndex:0];
	var i, cnt=arr.length;

	for(i=0; i<cnt; i++)
	{	className = [CPString stringWithFormat: arr[i], capitalizedTagName];
		c = CPClassFromString (className);
		if (c != Nil) return c;
	} return Nil;
}

- (Class) objectClassForTagName: (CPString)tagName
{	return [self objectClassForTagName: tagName
			mappedByFormatArray: [CPArray arrayWithObjects: @"GSMarkup%@Tag",@"GSMarkupTag%@", @"GS%@Tag", @"GSTag%@", @"%@Tag", @"Tag%@"]];
}

- (id) connectorClassForTagName: (CPString)tagName
{
  var capitalizedTagName;
  var className;
  var c;

  
  if (className != nil)
	{
	  c = CPClassFromString (className);
	  if (c != Nil)
	{
	  return c;
	}
	}

  switch ([tagName characterAtIndex: 0])
	{
	case 'c':
	  if ([tagName isEqualToString: @"control"])
	{
	  return [GSMarkupControlConnector class];
	}
	  break;
	case 'o':
	  if ([tagName isEqualToString: @"outlet"])
	{
	  return [GSMarkupOutletConnector class];
	}
	  break;
	}

	return [self objectClassForTagName: tagName
			mappedByFormatArray: [CPArray arrayWithObjects: @"GSMarkup%@Connector",  @"GSMarkupConnector%@",  @"GS%@Connector", @"GSConnector%@",  @"%@Connector",@"Connector%@"]];

}


- (id) attributesForDOMNode: aDOMNode
{	var attributes=aDOMNode.attributes;
	if(!attributes) return nil;
	var ret=[CPMutableDictionary dictionary];
	var i,cnt=attributes.length;
	for(i=0;i<cnt;i++)
	{	[ret setValue: attributes[i].nodeValue forKey:attributes[i].nodeName];
	}
	return ret;
}

- (id) insertChildrenOfDOMNode: aDOMNode intoContainer: container
{	if(!aDOMNode) return nil;
	var children;
	if (children=aDOMNode.childNodes)
	{	var tagChildren=[CPMutableArray new];
		var childrenCount=children.length;
		var i;
		for(i=0;i<childrenCount;i++)
		{	var co=[self insertMarkupObjectFromDOMNode:children[i] intoContainer: nil];
			if(co) [tagChildren addObject: co ];
			else
			{	var cnv=children[i].nodeValue;
				var ts=[cnv trimmedString];
				if( ts &&  ts.length) return [CPArray arrayWithObject: cnv];
			}
		}
		return tagChildren;
	}
	return nil;
}

- (id) insertMarkupObjectFromDOMNode: o intoContainer: container
{
	var nclass= (container==_connectors)? [self connectorClassForTagName: o.nodeName]:[self objectClassForTagName: o.nodeName];
	if (nclass)
	{

		var attribs=[self attributesForDOMNode: o];
		var oid=[attribs objectForKey:@"id"];
		if(!oid) oid=[CPString stringWithFormat: @"%@%d", o.nodeName, ++_uniqueID];

		var keys = [attribs allKeys];
		var  i, count = [keys count];
		for (i = 0; i < count; i++)
		{	var key, value;

			key = [keys objectAtIndex: i];
			if(![key length]) continue;
			value = [attribs objectForKey: key];

			if (container!=_connectors && [value hasPrefix: @"#"])
			{	if ([value hasPrefix: @"##"])
				{
					/* A leading doubled '#' is an escape sequence,
					 * so we must replace the value with a version in
					 * which the * escape character has been removed.
					 */
					[attribs setObject: [value substringFromIndex: 1]
						   forKey: key];
				}
				else
				{	var outlet;	// GSMarkupOutletConnector

					/* We pass the value unchanged to the outlet.  If
					 * value contains a key value path using dots, those
					 * will be processed by the outlet when it is
					 * established.  */
					var outlet = [[GSMarkupOutletConnector alloc] 
						   initWithSource: oid
						   target: value
						   label: key];
					if(outlet) [_connectors addObject: outlet];
					/* Hide the attribute - it has been already processed.  */
					[attribs removeObjectForKey: key];
				  }
			}
		}
//if(container==_connectors && _connectors.length) alert("tim "+o.nodeName+" "+[[_connectors objectAtIndex:0] description]);
		var newo= [[nclass alloc] initWithAttributes: attribs content: [self insertChildrenOfDOMNode: o intoContainer: container]];
		if(!newo) return nil;
		if(container) [container addObject:newo];
		if(container!=_connectors) [_nameTable setObject:newo forKey:oid];
		return newo;
	} return  nil;
}

- (id) parseXMLString: aXMLStr
{	function _parseXml(xmlStr)
	{	if (typeof window.DOMParser != "undefined") {
			return ( new window.DOMParser() ).parseFromString(xmlStr, "text/xml");
		} else if (typeof window.ActiveXObject != "undefined" && new window.ActiveXObject("Microsoft.XMLDOM")) {
			var xmlDoc = new window.ActiveXObject("Microsoft.XMLDOM");
			xmlDoc.async = "false";
			xmlDoc.loadXML(xmlStr);
			return xmlDoc;
		}
		else {
			throw new Error("No XML parser found");
		}
	}
	var t= _parseXml(aXMLStr);
	if(!t) return nil;
	return t;
}
- (id) initWithXMLString:aXMLStr
{
	_xmlStr=aXMLStr;
	_nameTable=[CPMutableDictionary dictionary];
	_tagNameToObjectClass=[CPMutableDictionary dictionary];
	_objects=[CPMutableArray array];
	_connectors=[CPMutableArray array];
	return self;
}
- (void) setObjectClass: (CPString)className
		 forTagName: (CPString)tagName
{
  [_tagNameToObjectClass setObject: className  forKey: tagName];
}

- (void) makeConnectorsFromDOMNode: aDOMNode
{	if(!aDOMNode) return;
	var children;
	if(children=aDOMNode.childNodes)
	{	var childrenCount=children.length;

		for(i=0;i<childrenCount;i++)
		{	[self insertMarkupObjectFromDOMNode: children[i] intoContainer: _connectors];
//alert([[_connectors objectAtIndex:0] description]);
		}
	}
}

-(void) parse
{
	var t=[self parseXMLString:_xmlStr];
	var objs= t.getElementsByTagName("objects");

	if (objs && objs[0].childNodes)
	{	var cns=objs[0].childNodes;
		var i,cnt=cns.length;
		for(i=0; i< cnt; i++)
		{	[self insertMarkupObjectFromDOMNode: cns[i] intoContainer: _objects];
		}
	}
// alert([_objects description]);
	var  cons= t.getElementsByTagName("connectors");
	if(cons) [self makeConnectorsFromDOMNode: cons[0]];
}
-(id) nameTable
{	return _nameTable;
}
-(id) objects
{	return _objects;
}
-(id) connectors
{	return _connectors;
}
@end

