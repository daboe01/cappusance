/* -*-objc-*-
   Author: Daniel Boehringer (2012)

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
*/ 

@import <Foundation/CPObject.j>
@import "GSMarkupConnector.j"

@implementation CPString (CapitalizedString)
- (CPString) stringByUppercasingFirstCharacter
{	var length = [self length];

	if (length < 1) return self;
	else {
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
	  
		if (length == 1)  return s;
		else  return [s stringByAppendingString: [self substringFromIndex: 1]];
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
	if (plist == nil) return nil;
	return plist;
}

- (id)initWithContentsOfFile:(CPString)aPath
{	return [self initWithContentsOfURL:[CPURL URLWithString:aPath]];
}
@end

@implementation GSMarkupDecoder: CPObject
{	var					_uniqueID;
	CPMutableDictionary _nameTable;
	CPDictionary		_externalNameTable;
	CPMutableDictionary _tagNameToObjectClass;
	CPString			_xmlStr;
	CPMutableArray		_objects;
	CPMutableArray		_connectors;
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
{	var c;
	var capitalizedTagName = [tagName stringByUppercasingFirstCharacter];

	var className = [_tagNameToObjectClass objectForKey: tagName];
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
{	if (tagName =="control")
	{	return [GSMarkupControlConnector class];
	} else if (tagName == "outlet")
	{	return [GSMarkupOutletConnector class];
	}
	return [self objectClassForTagName: tagName
			mappedByFormatArray: [CPArray arrayWithObjects: @"GSMarkup%@Connector",  @"GSMarkupConnector%@",  @"GS%@Connector", @"GSConnector%@",  @"%@Connector",@"Connector%@"]];
}



- (id) entityClassForTagName: (CPString)tagName
{	return [self objectClassForTagName: tagName mappedByFormatArray: [CPArray arrayWithObjects: @"GSMarkup%@"]];
}


- (id) attributesForDOMNode: aDOMNode
{	var attributes=aDOMNode.attributes;
	if(!attributes) return nil;
	var ret=[CPMutableDictionary dictionary];
	var i,cnt=attributes.length;
	for(i=0;i<cnt;i++)
	{	[ret setValue: attributes[i].nodeValue forKey: attributes[i].nodeName];
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
		{	var co=[self insertMarkupObjectFromDOMNode: children[i] intoContainer: nil];
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
	var nclass;
	nclass=[self objectClassForTagName: o.nodeName];
	if(!nclass) nclass=[self connectorClassForTagName: o.nodeName];
	if(!nclass) nclass=[self entityClassForTagName: o.nodeName];

	if (nclass)
	{	var attribs=[self attributesForDOMNode: o];
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
			{	if ([value  hasPrefix: @"##"])
				{	/* A leading doubled '#' is an escape sequence,
					 * so we must replace the value with a version in
					 * which the * escape character has been removed.
					 */
					[attribs setObject: [value substringFromIndex: 1] forKey: key];
				}
				else
				{	if(container==_entites)
					{	[attribs setObject: [GSMarkupConnector getObjectForIdString: [value substringFromIndex: 1] usingNameTable: _externalNameTable] forKey: key];
					} else if(key != 'itemsBinding')	// itemsBinding will be processed elsewhere
					{	var outlet;	// GSMarkupOutletConnector

						/* We pass the value unchanged to the outlet.  If
						 * value contains a key value path using dots, those
						 * will be processed by the outlet when it is
						 * established.  */
						var outlet = [[GSMarkupOutletConnector alloc] 
							   initWithSource: oid
							   target: value
							   label: key];
						if(outlet)
						{	[_connectors addObject: outlet];
							/* Hide the attribute - it has been already processed.  */
							[attribs removeObjectForKey: key];
						}
					}
				}
			}
		}
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
	_entites=[CPMutableArray array];
	return self;
}
- (void) setExternalNameTable:(CPDictionary) context
{	_externalNameTable=context;
}

- (void) setObjectClass: (CPString)className
		 forTagName: (CPString)tagName
{	[_tagNameToObjectClass setObject: className  forKey: tagName];
}

- (void) processDOMNode: aDOMNode intoContainer:(id) aContainer
{	if(!aDOMNode) return;
	var children;
	if (children = aDOMNode.childNodes)
	{	var childrenCount=children.length;

		for(i=0;i<childrenCount;i++)
		{	[self insertMarkupObjectFromDOMNode: children[i] intoContainer: aContainer];
		}
	}
}

// replace symbolic relationships in entities with the real objects
- (void) _postprocessEntities
{	var i, l=_entites.length;
	for(i=0;i<l;i++)
	{	var    e=_entites[i];
		var  eFS=[e platformObject];
		var rels=[eFS relationships];
		if(!rels) continue;
		var j,l1=rels.length;
		for(j=0;j<l1;j++)
		{	[rels[j] setTarget: [[_nameTable objectForKey: [rels[j] target] ] platformObject] ];
		}
	}
}
- (void) _postprocessArray:(CPArray) someArr
{	var i, l=someArr.length;
	for(i=0;i<l;i++)
	{	var o=someArr[i];
		if(![o respondsToSelector:@selector(platformObject)]) continue;
		var oPO=[o platformObject];
		var peek;
		if (peek=[[o attributes] objectForKey: "valueBinding"])
		{	var r = [peek rangeOfString: @"."];
			if (r.location == CPNotFound)	// "unspecific" binding, such as in tableViews, where you do not want to connect the columns individually
			{	if([oPO isKindOfClass: [CPTableView class] ])
				{	var target=[[_nameTable objectForKey: peek] platformObject];
					[oPO bind:@"content" toObject: target withKeyPath: @"contentArray" options:nil]; 
					var _content=[o content];
					var j, l1 = _content.length;
					for (j = 0; j < l1; j++)
					{	var column =_content[j];
						if (column && [column  isKindOfClass: [GSMarkupTagTableColumn class]])
						{    [[column platformObject]	bind: CPValueBinding
													toObject: target
												 withKeyPath: @"arrangedObjects."+[[column attributes] objectForKey:"identifier"]
													 options: nil]; 
						}
					}
				}
			}
			else
			{	var objectName = [peek substringToIndex: r.location];
				var keyValuePath = [peek substringFromIndex: CPMaxRange(r)];
				var target = [[_nameTable objectForKey: objectName] platformObject];
				var binding=CPValueBinding;
				if([oPO isKindOfClass: [CPArrayController class]]) binding="contentArray";

//<!>				if(objectName.length) [oPO bind: binding toObject: target withKeyPath: keyValuePath options:nil];
			}
		}
		if (peek=[[o attributes] objectForKey: "itemsBinding"])		// items such as in pull-down or combobox
		{	var r = [peek rangeOfString: @"."];
			if (r.location == CPNotFound)	// "unspecific" binding, <!> fixme: i am currently not sure what this means
			{
			} else
			{	var list;
				r = [peek rangeOfString: @"." options: CPBackwardsSearch];
				if ([peek hasPrefix: @"#"])
				{	 list =[GSMarkupConnector getObjectForIdString:[peek substringWithRange: CPMakeRange(1,r.location-1)] usingNameTable: _externalNameTable];
				} else list=[[GSMarkupConnector getObjectForIdString:[peek substringWithRange: CPMakeRange(0,r.location)] usingNameTable: _nameTable] platformObject];
				var face = [peek substringFromIndex: CPMaxRange(r)];
				if([oPO isKindOfClass: [CPPopUpButton class]])	// insert popupbutton items from target datasource
				{
					if(list)
					{	var peek;
						var valFace;
						if (peek=[[o attributes] objectForKey: "valueBinding"])
						{	r = [peek rangeOfString: @"." options: CPBackwardsSearch];
							if(r.location!=CPNotFound)
							{	valFace=[peek substringFromIndex:r.location];
							}
						}
						var j, l1 = list.length;
						for (j = 0; j < l1; j++)
						{	var item  =list[j];
							var newItem=[[CPMenuItem alloc] initWithTitle: [item valueForKey: face] action:NULL keyEquivalent:nil];
							if(valFace) [newItem setTag: [item valueForKey: valFace] ];
							[oPO addItem: newItem];
						}
					}
				}
			}
		}
		if([oPO isKindOfClass: [CPArrayController class]])		// autofetching
		{	if( [o boolValueForAttribute: "autoFetch"] == 1 )
			{	var entityName=[[o attributes] objectForKey: "entity"];
				if (entityName)
				{	var entity;
					if (entity=[[_nameTable objectForKey: entityName ] platformObject])
					{	[oPO setContent: [entity allObjects] ];
					}
				}
			}
		} [self _postprocessArray:[o content]];
	}
}

-(void) parse
{	var t= [self parseXMLString:_xmlStr];

	var objs= t.getElementsByTagName("objects");
	if(objs) [self processDOMNode: objs[0] intoContainer: _objects];

	var  entities= t.getElementsByTagName("entities");
	if(entities)
	{	[self processDOMNode: entities[0] intoContainer: _entites];
		[self _postprocessEntities];
	}
	[self _postprocessArray:_objects];

	var  cons= t.getElementsByTagName("connectors");
	if(cons) [self processDOMNode: cons[0] intoContainer: _connectors];
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
-(id) entities
{	return _entities;
}
@end

