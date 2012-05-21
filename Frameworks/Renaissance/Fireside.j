/*
 * Fireside: yet another restful ORM mapper for cappuccino
 * ToDo:
 *	Store refactoring: FSAbstractStore with a Store for the Mojolicious example-backend.
 *  Check whether quoting is necessary in keys and vals (FSStore).
 *  catch write conflicts.
 *	TableView: looses changes when changing selection during edit: https://github.com/cappuccino/cappuccino/issues/1435
 *  invalidate relation caches when objects are added or removed from inside Fireside.
 *  make use of websockets to push backend changes to Fireside
 */

@import <Foundation/CPObject.j>

@implementation CPArray(AllObjects)
-(CPArray) allObjects {return self;}
@end

@implementation CPDictionary(JSONExport)
-(CPString) toJSON
{	var keys=[self allKeys];
	var i,l=keys.length;
	var o={};
	for(i=0;i<l;i++)
	{	var key=keys[i];
		o[key]=[self objectForKey:key];
	}
	return JSON.stringify(o);
}
@end


@implementation FSStore : CPObject 
{	CPString _baseURL @accessors(property=baseURL);
	unsigned _fetchLimit @accessors(property=fetchLimit);
}

-(id) initWithBaseURL:(CPString) someURL
{	self = [super init];
    if (self)
	{	_baseURL = someURL;
    }
    return self;
}

-(CPURLRequest) requestForWritingDictionary:(CPDictionary) obj toPK:(id) somePK inEntity:(FSEntity) someEntity
{	var request = [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+[someEntity pk]+"/"+somePK ];
    [request setHTTPMethod:"PUT"];
	[request setHTTPBody: [obj toJSON] ];
	return request;
}

-(void) writeChangesInObject: (id) obj
{	var request=  [self requestForWritingDictionary: obj._changes toPK: [obj valueForKey: [[obj entity] pk]] inEntity: [obj entity]];
	[CPURLConnection sendSynchronousRequest:request returningResponse: nil];
}

-(CPArray) fetchObjectsForURLRequest:(CPURLRequest) request inEntity: (FSEntity) someEntity
{	var data=[CPURLConnection sendSynchronousRequest: request returningResponse: nil];
	var j = JSON.parse( [data rawString]);
	var a=[CPMutableArray new];
	var i,l=j.length;
	for(i=0;i<l;i++)
	{	var pk=j[i][[someEntity pk]];
		var peek;
		if (peek=[someEntity _registeredObjectForPK: pk])	// enforce singleton pattern
		{	[a addObject:peek]; 
		} else
		{	var t=[[FSObject alloc] initWithEntity: someEntity];
			[t _setDataFromJSONObject: j[i]];
			[someEntity _registerObjectInPKCache: t];
			[a addObject:t];
		}
	}
	return a;
}
-(CPURLRequest) requestForFetchingAllObjectsInEntity:(FSEntity) someEntity
{	return [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name] ];
}
-(CPArray) fetchAllObjectsInEntity:(FSEntity) someEntity
{	return [self fetchObjectsForURLRequest: [self requestForFetchingAllObjectsInEntity: someEntity] inEntity:someEntity];
}

-(CPURLRequest) requestForFetchingObjectsWithKey: aKey equallingValue: (id) someval inEntity:(FSEntity) someEntity
{	var request = [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+aKey+"/"+someval];
	return request;
}

-(id) fetchObjectsWithKey: aKey equallingValue: (id) someval inEntity:(FSEntity) someEntity
{	if( aKey == [someEntity pk] ) 
	{	var peek;
		if(peek=[someEntity _registeredObjectForPK: someval]) return [CPArray arrayWithObject: peek];
	}

	var request =[self requestForFetchingObjectsWithKey: aKey equallingValue: someval inEntity: someEntity];
	return [self fetchObjectsForURLRequest: request inEntity: someEntity];
}

@end

FSRelationshipTypeToOne=0;
FSRelationshipTypeToMany=1;

@implementation FSRelationship : CPObject 
{	CPString _name @accessors(property=name);
	FSEntity _source @accessors(property=source);
	FSEntity _target @accessors(property=target);
	CPString _bindingColumn @accessors(property=bindingColumn);
	CPString _targetColumn @accessors(setter=setTargetColumn:);
	CPString _type @accessors(property=type);
	var _target_cache;
}
-(id) initWithName:(CPString) aName source: someSource andTargetEntity:(FSEntity) anEntity
{	self = [super init];
    if (self)
	{	_target = anEntity;
		_name = aName;
		_source = someSource;
		_type= FSRelationshipTypeToOne;
    }
	[FSEntity _registerRelationship:self];
    return self;

}
-(id) init
{	return [self initWithName: nil source: nil andTargetEntity: nil];
}
-(CPString) targetColumn
{	if(_targetColumn && _targetColumn.length) return _targetColumn;
	return [_target pk];
}
-(CPArray) fetchObjectsForKey:(id) targetPK
{	if(!targetPK) return nil;
	var peek;
	if(!_target_cache) _target_cache=[];
	if(peek=_target_cache[targetPK]) return peek;
	var res= [[_target store] fetchObjectsWithKey: [self targetColumn] equallingValue: targetPK inEntity: _target];
	_target_cache[targetPK]=res;
	return res;
}

-(void) invalidateCache
{	_target_cache=[];
	if([_target _hasCaches]) [_target invalidateRelationshipCaches];
}
@end

var _allRelationships;
@implementation FSEntity : CPObject 
{	CPString _name @accessors(property=name);
	CPString _pk @accessors(property=pk);
	CPSet _columns @accessors(property=columns);
	CPSet _relations;
	FSStore	_store @accessors(property=store);
	CPMutableArray _pkcache;
	CPMutableDictionary _formatters;
}
+(CPArray) relationshipsWithTargetProperty: aKey
{	var ret=[];
	if(!_allRelationships) return ret;
	var i,l=_allRelationships.length;
	for(i=0;i<l;i++)
	{	var r=_allRelationships[i];
		if([r targetColumn] == aKey) [ret addObject: r];
	}
	return ret;
}
+(void) _registerRelationship:(FSRelationship) someRel
{	if(!_allRelationships) _allRelationships=[CPMutableArray new];
	return [_allRelationships addObject: someRel];
}


-(id) initWithName:(CPString) aName andStore:(FSStore) someStore
{	self = [super init];
    if (self)
	{	_store = someStore;
		_name = aName;
    }
    return self;
}
-(id) init
{	return [self initWithName: nil andStore: nil];
}

-(void) setFormatter: (CPFormatter) aFormatter forColumnName:(CPString) aName
{	if(!_formatters) _formatters=[CPMutableDictionary new];
	[_formatters setObject:aFormatter forKey: aName];
}
-(CPFormatter) formatterForColumnName:(CPString) aName
{	if(!_formatters) return nil;
	return [_formatters objectForKey: aName];
}

-(id) objectWithPK:(id) somePK
{	var a=[[self store] fetchObjectsWithKey: [self pk] equallingValue: somePK inEntity: self];
	if(a.length==1) return a[0];
	return nil;
}

-(FSRelationship) relationOfName:(CPString) aName
{	var rels=[_relations allObjects];
	var i,l=rels.length;
	for(i=0;i<l;i++)
	{	var r=rels[i];
		if([r name]==aName) return r;
	}
	return nil;
}
-(CPArray) relationships
{	return [_relations allObjects];
}


-(void) addRelationship:(FSRelationship) someRel
{	if(!_relations) _relations=[CPSet setWithObject:someRel];
	else [_relations addObject: someRel];
}

-(CPArray) allObjects
{
	return [_store fetchAllObjectsInEntity: self];
}

-(void) _registerObjectInPKCache:(id) someObj
{	if(!_pkcache) _pkcache=[CPMutableArray new];
	_pkcache[[someObj valueForKey:_pk]]=someObj;
}
-(void) _registeredObjectForPK:(id) somePK
{	if(!_pkcache) return nil;
	return _pkcache[somePK];
}
-(void) invalidateRelationshipCaches
{	[_relations makeObjectsPerformSelector: @selector(invalidateCache)];
}
-(BOOL) _hasCaches
{	var rels=[_relations allObjects];
	var i,l=rels.length;
	for(i=0;i<l;i++)
	{	var r=rels[i];
		if(r._target_cache && r._target_cache.length) return YES;
	}
	return NO;
}
@end

@implementation FSObject : CPObject 
{	CPMutableDictionary _data;
	CPMutableDictionary _changes;
	CPMutableDictionary _formatters;
	FSEntity _entity @accessors(property=entity);
}

-(id) initWithEntity:(id) anEntity
{	self = [super init];
    if (self)
	{	_entity=anEntity;
    }
    return self;
}

- (void)_setDataFromJSONObject:(id) o
{	_data = [CPMutableDictionary dictionary];
	var cols=[[_entity columns] allObjects];
	var i,l=cols.length;
    for(i=0; i<l; i++)
    {	var propName = cols[i];
		[_data setObject: o[propName] forKey:propName];
    }
}
-(void) setFormatter: (CPFormatter) aFormatter forColumnName:(CPString) aName
{	if(!_formatters) _formatters=[CPMutableDictionary new];
	[_formatters setObject:aFormatter forKey: aName];
}
-(CPFormatter) formatterForColumnName:(CPString) aName
{	if(!_formatters) return nil;
	return [_formatters objectForKey: aName];
}

- (id)description
{	return [_data description];
}

-(int) typeOfKey:(CPString)aKey
{	if( [[_entity columns] containsObject: aKey]) return 0;
	if( [_entity relationOfName: aKey]) return 1;
	return CPNotFound;
}

- (id)valueForKey:(CPString)aKey
{	var type= [self typeOfKey: aKey];

	if(type == 0)
	{	if(!_data)		// <!>fixme: implement lazy (batch-) fetching here
		{
		}
	
		var  o=[_changes objectForKey: aKey];
		if (!o)  o = [_data objectForKey: aKey];
		if  (o)
		{	if(![o isKindOfClass:[CPString class]])	// cast numbers to strings in order to make predicate filtering work
				 o=[o stringValue];
		}
		var peek=[self formatterForColumnName:aKey];
		if(peek || (peek=[_entity formatterForColumnName:aKey]))
		{	return [peek stringForObjectValue: o];
		} else return o;
	} else if(type == 1)	// to one relation: aKey is accessed
	{	var rel=[_entity relationOfName: aKey];
		var bindingColumn=[rel bindingColumn];
		if(!bindingColumn) bindingColumn=[_entity pk];

		var results=[rel fetchObjectsForKey: [self valueForKey: bindingColumn] ];

		return [rel type]== FSRelationshipTypeToMany? results: ((results && results.length)? [results objectAtIndex: 0] : nil) ;
	} else
	{	var propSEL = sel_getName(aKey);
		if(propSEL && [self respondsToSelector: propSEL ]) return [self performSelector:propSEL];
		else [CPException raise:CPInvalidArgumentException reason:@"Key "+aKey+" is not a column in entity "+[_entity name]];
	}
	
}

- (void)setValue: someval forKey:(CPString)aKey
{	var type= [self typeOfKey: aKey];
	var oldval=[self valueForKey: aKey];
	if(type == 0)
	{	if(!_changes) _changes = [CPMutableDictionary dictionary];
		[self willChangeValueForKey:aKey];

		var peek=[self formatterForColumnName: aKey];
		if(peek || (peek=[_entity formatterForColumnName: aKey]))
		{	someval= [peek objectValueForString: someval error: nil];	//<!> fixme handle errors somehow
		}
		[_changes setObject: someval forKey: aKey];
		[self didChangeValueForKey:aKey];
		[[_entity store] writeChangesInObject: self];
		var peekRels=[FSEntity relationshipsWithTargetProperty: aKey];
		if (peekRels) //if we write to a relationship key: update the target array forcing an update of the arraycontrollers
		{	var i,l=peekRels.length;
			for(i=0; i<l; i++)
			{	var rel = peekRels[i];
				if([rel type] == FSRelationshipTypeToMany)
				{	[rel invalidateCache];
					var affectedObject=[[rel source] objectWithPK: oldval];	// force updating the current selection in the arraycontrollers
					var newValOfAffectedObject= [rel fetchObjectsForKey: oldval]
					[affectedObject willChangeValueForKey: [rel name]];
					[affectedObject setValue: newValOfAffectedObject forKey: [rel name] ];
					[affectedObject didChangeValueForKey: [rel name]];
				}
			}
		}
	} else if(type == 1)
	{	// this is only to make KVC upates happen in order to update theu selection in the arraycontrollers.
	}
	else [CPException raise:CPInvalidArgumentException reason:@"Key "+aKey+" is not a column"];
}

- (void)insertObjects:(CPArray) theObjects atIndexes:(CPSet)theIndexes
{
document.title="insertObjects";
	// <!> fixme do something reasonable
}

@end
