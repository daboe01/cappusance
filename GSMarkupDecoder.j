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

+ initialize
{	if(self=[super initialize])
	{
	}
	return self;
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
{	if (tagName == "control")
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

			if (container !== _connectors && (  key === 'delegate' || [value hasPrefix: @"#"]) )
			{	if(container === _entites)
				{	[attribs setObject: [GSMarkupConnector getObjectForIdString: [value substringFromIndex: 1] usingNameTable: _externalNameTable] forKey: key];
				} else if(key !== 'itemsBinding' && key !== 'valueBinding' && key !== 'enabledBinding')	// bindings will be processed elsewhere
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
			xmlDoc.async = false;
			xmlDoc.validateOnParse = false;
			xmlDoc.loadXML(xmlStr);
			if (xmlDoc.parseError.errorCode != 0)
			{	alert("Error in line " + xmlDoc.parseError.line +
						" position " + xmlDoc.parseError.linePos +
						"\nError Code: " + xmlDoc.parseError.errorCode +
						"\nError Reason: " + xmlDoc.parseError.reason +
						"Error Line: " + xmlDoc.parseError.srcText);
			}
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
{	_xmlStr=aXMLStr;
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
-(id) _getObjectForIdString:(CPString) peek
{	var ret;
	if ([peek hasPrefix: @"#"])
	{	 ret =[GSMarkupConnector getObjectForIdString: [peek substringFromIndex:1] usingNameTable: _externalNameTable];	// external objects are already platformObjects
	} else ret= [GSMarkupConnector getPlatformObjectForIdString: peek usingNameTable: _nameTable];
	return ret;
}

- (void) _postprocessForBindings:(CPArray) someArr
{	var i, l=someArr.length;
	for(i=0;i<l;i++)
	{	var o=someArr[i];
		if(![o respondsToSelector:@selector(platformObject)]) continue;
		var oPO=[o platformObject];
		var peek;
		if (peek=[[o attributes] objectForKey: "itemsBinding"])		// items such as in pull-down or combobox
		{	var r = [peek rangeOfString: @"."];
			if (r.location != CPNotFound)
			{	r = [peek rangeOfString: @"." options: CPBackwardsSearch];
				var pathComponents=[peek componentsSeparatedByString:"."];
				var subPathArray=[pathComponents subarrayWithRange: CPMakeRange(0, pathComponents.length-2)];
				var baseObjectPath=(subPathArray.length>1)? subPathArray.join("."):subPathArray[0];
				var arrCtrl= [self _getObjectForIdString: baseObjectPath];
				var itemsFace = [peek substringFromIndex: CPMaxRange(r)];
				var valItemsFace=[arrCtrl pk];

				if([oPO isKindOfClass: [CPPopUpButton class]])
				{	if(itemsFace && valItemsFace)
					{	[oPO bind:"itemArray" toObject: arrCtrl withKeyPath: "arrangedObjects."+itemsFace   options: @{"valueFace": valItemsFace}];
					}
				} else if([oPO isKindOfClass: [CPSegmentedControl class]])
				{
                	if(itemsFace && valItemsFace)
					{	[oPO bind:"segments" toObject: arrCtrl withKeyPath: "arrangedObjects."+itemsFace   options: @{"valueFace": valItemsFace}];
					}
				} else if([oPO isKindOfClass: [CPComboBox class] ])
				{	[oPO bind: CPContentValuesBinding  toObject: arrCtrl withKeyPath: "arrangedObjects."+itemsFace options:nil];
				}
			}
		}
		if (peek=[[o attributes] objectForKey: "valueBinding"])
		{	var r = [peek rangeOfString: @"."];

			if ([oPO isKindOfClass: [CPTableView class] ])
			{	var target=[self _getObjectForIdString: peek];
				if([o boolValueForAttribute: "viewBasedBindings"] == 1)
				{	[oPO bind: "content"          toObject: target withKeyPath:"arrangedObjects" options: nil];
					[oPO bind: "selectionIndexes" toObject: target withKeyPath:"selectionIndexes" options:nil];
				} else		// "explicit" bindings for tableView columns, where you do not want to connect the columns individually but through "identifier" property
				{	var _content=[o content];
					var j, l1 = _content? _content.length:0;
					for(j = 0; j < l1; j++)
					{	var column = _content[j];
						if (column && [column  isKindOfClass: [GSMarkupTagTableColumn class]])
						{	[[column platformObject]	bind: CPValueBinding
													toObject: target
												 withKeyPath:@"arrangedObjects."+[[column attributes] objectForKey:"identifier"]
													 options: nil];
							if(target) target.__tableViewForSpinner=[[column platformObject] tableView];
						}
					}
				}
			}
			else
			{	var objectName = [peek substringToIndex: r.location];
				var target = [self _getObjectForIdString: objectName];

				var keyValuePath = [peek substringFromIndex: CPMaxRange(r)];

				var binding=CPValueBinding;
				if([oPO  isKindOfClass: [FSArrayController class]])
				{	binding="contentArray";
				} else if([oPO isKindOfClass: [CPPopUpButton class]])
				{	binding="selectedTag";
				}
				var options=nil;
				if([[o attributes] objectForKey: "continuousBinding"]==="YES") options=@{CPContinuouslyUpdatesValueBindingOption:YES};
				[oPO bind: binding toObject: target withKeyPath: keyValuePath options: options ];
				if([oPO isKindOfClass: [CPCollectionView class]])
				{
					if (r.location != CPNotFound)
					{	var pathComponents=[peek componentsSeparatedByString:"."];
						if(pathComponents.length>2)
						{	var subPathArray=[pathComponents subarrayWithRange: CPMakeRange(1, pathComponents.length-2)];
							keyValuePath =subPathArray.join(".")+".selectionIndexes";
						} else keyValuePath="selectionIndexes";
					} else keyValuePath="selectionIndexes"
					[oPO bind: "selectionIndexes" toObject: target withKeyPath: keyValuePath options: nil ];
				}
			}
		}
        if (peek=[[o attributes] objectForKey: "enabledBinding"])
		{	var r = [peek rangeOfString: @"."];
            var objectName = [peek substringToIndex: r.location];
            var target = [self _getObjectForIdString: objectName];
            var keyValuePath = [peek substringFromIndex: CPMaxRange(r)];
            var binding=CPEnabledBinding;
			var options=nil;
			[oPO bind: binding toObject: target withKeyPath: keyValuePath options: options ];

        }
		if (peek=[[o attributes] objectForKey: "filterPredicate"])
		{	if( [oPO isKindOfClass: [FSArrayController class]])
			{	[oPO setClearsFilterPredicateOnInsertion:NO];
				[oPO setFilterPredicate: [self _getObjectForIdString: peek] ];
			}
		}
		if (peek=[[o attributes] objectForKey: "formatterClass"])
		{	var displayFormat=[[o attributes] objectForKey: "displayFormat"];
			var editingFormat=[[o attributes] objectForKey: "editingFormat"];
			var emptyIsValid=([o boolValueForAttribute: "editingFormat"]==1);
			if(!displayFormat && !editingFormat)
				 [oPO setFormatter: [CPClassFromString(peek) new]];
			else [oPO setFormatter: [CPClassFromString(peek)
					formatterWithDisplayFormat: displayFormat
					editingFormat: editingFormat
					emptyIsValid: emptyIsValid]];

		}
		[self _postprocessForBindings:[o content]];
	}
}
- (void) _postprocessForEntities:(CPArray) someArr
{	var i, l=someArr.length;
	for(i=0;i<l;i++)
	{	var o=someArr[i];
		if(![o respondsToSelector:@selector(platformObject)]) continue;
		var oPO=[o platformObject];
		if([oPO isKindOfClass: [FSArrayController class]])		// autofetching
		{	var peek;
			if(peek=[[o attributes] objectForKey: "sortDescriptor"])
			{	[oPO setSortDescriptors: [  [self _getObjectForIdString: peek ]  ] ];
			}
			if (peek=[[o attributes] objectForKey:"entity"])
			{	var entity=[[_nameTable objectForKey: peek] platformObject];
				[oPO setEntity: entity];
			}
			if( [o boolValueForAttribute: "autoFetch"] == 1 )
			{	var entityName=[[o attributes] objectForKey: "entity"];
				if (entityName)
				{	var entity;
					if (entity=[[_nameTable objectForKey: entityName ] platformObject])
					{	[oPO setContent: [entity allObjects] ];
					}
				}
			}
		} [self _postprocessForEntities:[o content]];
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

	var  cons= t.getElementsByTagName("connectors");
	if(cons) [self processDOMNode: cons[0] intoContainer: _connectors];

	[self _postprocessForEntities:_objects];
	[self _postprocessForBindings:_objects];
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

