
@import "GSMarkupTagObject.j"
@import <Foundation/CPObject.j>
@import <AppKit/CPArrayController.j>
@import "Fireside.j"

@implementation GSMarkupColumn: GSMarkupTagObject

+ (CPString) tagName
{
  return @"column";
}
-(CPString) name
{	return [_attributes objectForKey: @"name"];
}
-(BOOL) isPK
{	return [self boolValueForAttribute: @"primaryKey"]==1;
}
/* Will never be called.  */
- (id) allocPlatformObject
{	return nil;
}
@end

@implementation GSMarkupRelationship: GSMarkupTagObject
+ (CPString) tagName
{
  return @"relationship";
}
- (BOOL) runSynced
{	return [self boolValueForAttribute:"runSynced"]==1;
}
-(CPString) name
{	return [_attributes objectForKey: @"name"];
}
-(CPString) target
{	return [_attributes objectForKey: @"target"];
}
-(CPString) targetColumn
{	return [_attributes objectForKey: @"targetColumn"];
}
-(CPString) bindingColumn
{	return [_attributes objectForKey: @"bindingColumn"];
}
-(BOOL) isToMany
{	return [_attributes objectForKey: @"type"] === "toMany";
}
@end


@implementation GSMarkupEntity: GSMarkupTagObject
+ (CPString) tagName
{
  return @"entity";
}

+ (Class) platformObjectClass
{	return [FSEntity class];
}

- (id) initPlatformObject: (id)platformObject
{	var store = [_attributes objectForKey: @"store"];

	var name = [_attributes objectForKey: @"id"];
	platformObject = [platformObject initWithName: name andStore: store ];

// now extract columns and PK...
	var myCols=[CPMutableSet new];

	var myPK;
    var i, count = _content?_content.length:0;
	for (i = 0 ; i < count; i++)
	{	var v = _content[i];
		if([v isKindOfClass: [GSMarkupColumn class] ])
		{	if([v isPK])
			{	if(myPK) [CPException raise:CPInvalidArgumentException reason:@"Duplicate PK "+[v name]+"! "+ myPK+" already is PK!"];
				else myPK=[v name];
			}
			[myCols addObject: [v name]];
		} else if([v isKindOfClass: [GSMarkupRelationship class] ])
		{	var rel=[[FSRelationship alloc] initWithName: [v name] source: platformObject andTargetEntity: [v target]];	//set name as a temorary symbolic link. will be resolved in decoder later on.
			if([v bindingColumn]) [rel setBindingColumn: [v bindingColumn] ];
			if([v targetColumn]) [rel setTargetColumn: [v targetColumn] ];
			if([v isToMany]) [rel  setType: FSRelationshipTypeToMany];
			else [rel setType: FSRelationshipTypeToOne];
			if([v runSynced]) [rel setRunSynced:YES];
			[platformObject addRelationship: rel];
		}
	}
	[platformObject setColumns:myCols];
	if(myPK) [platformObject setPk: myPK];
	return platformObject;
}

@end


@implementation FSArrayController: CPArrayController
{	id _entity @accessors(property=entity);
	id _defaultDict;
}
-(CPString) pk
{	return [_entity pk];

}
-(void) setEntity: anEntity
{	_entity=anEntity;
	_entity.__ACForSpinner=self;
}
-(void) selectObjectWithPK: myPk
{	var o= [_entity objectWithPK: myPk];
	[self setSelectedObjects: [o] ];
}

- (id)selectedObject
{	var s=[self selectedObjects];
	return [s count]? [s objectAtIndex:0]:nil;
}
- (id)_defaultNewObject
{	return [_entity createObjectWithDictionary: _defaultDict];
}
- (void)setContent:(id)value
{	if(!value || (value.hasOwnProperty('_proxyObject') && ![value._proxyObject isKindOfClass:[CPArray class]]))
	{	value= [_entity _arrayForArray: [] withDefaults: _defaultDict ];
	}

	if([value respondsToSelector: @selector(defaults) ])
	{	_defaultDict=[[value defaults] copy];
	}
	[super setContent: value];
}
-(BOOL)hasSelection
{   return [[self selectedObjects] count] > 0;
}
-(BOOL)hasSingleRowSelection
{   return [[self selectedObjects] count] == 1;
}
-(BOOL)hasTwoRowsSelected
{   return [[self selectedObjects] count] == 2;
}

-(void) addObject: anObject
{	if(![anObject isKindOfClass: [FSObject class] ] )
		anObject=[_entity createObjectWithDictionary:anObject];

	[super addObject: anObject];
}

//<!> fixes an issue when adding to an empty arraycontroller
- (void)insertObject:(id)anObject atArrangedObjectIndex:(int)anIndex
{	[super insertObject: anObject atArrangedObjectIndex:MAX(0,anIndex)];
}

-(void) reload
{
	[[FSRelationship relationshipsWithTargetEntity:_entity] makeObjectsPerformSelector:@selector(_invalidateCache)];
    [[[[self class] _binderClassForBinding:@"contentArray"] getBinding:@"contentArray" forObject:self] setValueFor:@"contentArray"];
}
@end

@implementation GSMarkupArrayController: GSMarkupTagObject
+ (CPString) tagName
{	return @"arrayController";
}

+ (Class) platformObjectClass
{	return [FSArrayController class];
}

- (id) initPlatformObject: (id)platformObject
{	platformObject = [platformObject init];
	[platformObject setAutomaticallyRearrangesObjects: YES];
	[platformObject setClearsFilterPredicateOnInsertion:NO];	//<!> fixme: make this configurable via markup
	[platformObject setObjectClass:[FSObject class]];
	[platformObject setEntity: [_attributes objectForKey: @"entity"] ];
	return platformObject;
}

@end
