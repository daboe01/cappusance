/*
 * Fireside: yet another restful ORM mapper for cappuccino
 * ToDo:
 *  catch write conflicts as in original EOF.
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPDictionary.j>
@import "FSMutableArray.j"

@implementation CPNull(FSFix)
-stringValue{return "NULL"}
@end
@implementation CPArray(AllObjects)
-(CPArray) allObjects {return self;}
@end

@implementation CPDictionary(JSONExport)
-(CPString) toJSON
{   var keys=[self allKeys];
    var i,l=keys.length;
    var o={};
    var nullobj=[CPNull null]
    for(i=0;i<l;i++)
    {   var key=keys[i];
        var peek=[self objectForKey:key];
        o[key]=peek === nullobj? 'NULL': peek;
    }
    return JSON.stringify(o);
}
@end

@implementation FSEntity : CPObject 
{   CPString    _name @accessors(property=name);
    CPString    _pk @accessors(property=pk);
    CPSet        _columns @accessors(property=columns);
    CPSet        _relations;
    CPSet        _numerics;
    FSStore        _store @accessors(property=store);
    CPMutableArray _pkcache;
    CPMutableDictionary _formatters;
}

-(CPArray)_arrayForArray: results withDefaults: someDefaults
{   var r=[[FSMutableArray alloc] initWithArray: results ofEntity: self];
    [r setDefaults: someDefaults];
    return r;
}


-(id) initWithName:(CPString) aName andStore:(FSStore) someStore
{   self = [super init];
    if (self)
    {   _store = someStore;
        _name = aName;
    }
    return self;
}
-(id) init
{   return [self initWithName: nil andStore: nil];
}

-(id) createObject
{   return [self createObjectWithDictionary:nil];
}

-(id) createObjectWithDictionary:(CPDictionary) myDict
{   var r=[[FSObject alloc] initWithEntity:self];
    if(myDict)
    {   r._changes=[myDict copy];
        var allKeys=[myDict allKeys];
        var i, l=[allKeys count]
        for(i=0; i< l; i++)
        {   var aKey=[allKeys objectAtIndex: i];
            var someval=[myDict objectForKey: aKey];
            var peek;
            if (peek=[self formatterForColumnName: aKey])
            {   someval= [peek objectValueForString: someval error: nil];    //<!> fixme handle errors somehow
                [myDict setObject: someval forKey: aKey];
            }
        }
    }
    return r;
}

-(FSObject) insertObject:(id)someObj
{   if([someObj isKindOfClass: [CPDictionary class]])
    {   someObj=[self createObjectWithDictionary: someObj];
    } else if(![someObj isKindOfClass: [FSObject class]])
    {   //<!> fixme warn or raise...
    }
    [_store insertObject: someObj];
    return someObj;
}
-(void) deleteObject:(id)someObj
{
    [_store deleteObject: someObj];
}

-(void) setFormatter: (CPFormatter) aFormatter forColumnName:(CPString) aName
{   if(!_formatters) _formatters=[CPMutableDictionary new];
    [_formatters setObject:aFormatter forKey: aName];
}
-(CPFormatter) formatterForColumnName:(CPString) aName
{   if(!_formatters) return nil;
    return [_formatters objectForKey: aName];
}

-(id) objectWithPK:(id) somePK
{   var myoptions=[CPDictionary dictionaryWithObject: "1" forKey: "FSSynchronous"];

    var a=[[self store] fetchObjectsWithKey: [self pk] equallingValue: somePK inEntity: self options: myoptions];
    if([a count]==1) return [a objectAtIndex: 0];
    return nil;
}

-(FSRelationship) relationOfName:(CPString) aName
{   var rels=[_relations allObjects];
    var i,l=[rels count];
    for(i=0;i<l;i++)
    {   var r=rels[i];
        if([r name]==aName) return r;
    }
    return nil;
}
-(CPArray) relationships
{   return [_relations allObjects];
}


-(void) addRelationship:(FSRelationship) someRel
{   if(!_relations) _relations=[CPSet setWithObject:someRel];
    else [_relations addObject: someRel];
}
-(void) addNumericColumn:(CPString) aCol
{   if(!_numerics) _numerics =[CPSet setWithObject:aCol];
    else [_numerics addObject: aCol];
}
-(BOOL) isNumericColumn:(CPString) aCol
{   return [_numerics containsObject: aCol];
}

-(CPArray) allObjects
{
    return [_store fetchAllObjectsInEntity: self];
}

-(void) _registerObjectInPKCache:(id) someObj
{   if(!_pkcache) _pkcache=[CPMutableArray new];
    if(_pk) _pkcache[[someObj valueForKey:_pk]]=someObj;
}
-(void) _registeredObjectForPK:(id) somePK
{   if(!_pkcache) return nil;
    return _pkcache[somePK];
}
-(BOOL) _hasCaches
{   var rels=[_relations allObjects];
    var i,l=[rels count];
    for(i=0;i<l;i++)
    {   var r=[rels objectAtIndex: i];
        if (r._target_cache && [r._target_cache count]) return YES;
    }
    return NO;
}
-(void) _invalidatePKCache
{   _pkcache=[];
}

@end


FSRelationshipTypeToOne=0;
FSRelationshipTypeToMany=1;
FSRelationshipTypeFuzzy=2;

var _allRelationships;

@implementation FSRelationship : CPObject 
{   CPString _name @accessors(property=name);
    FSEntity _source @accessors(property=source);
    FSEntity _target @accessors(property=target);
    CPString _bindingColumn @accessors(property=bindingColumn);
    CPString _targetColumn @accessors(setter=setTargetColumn:);
    CPString _type @accessors(property=type);
    var         _target_cache;
    var         _runSynced @accessors(property=runSynced);
}
-(id) initWithName:(CPString) aName source: someSource andTargetEntity:(FSEntity) anEntity
{   self = [super init];
    if (self)
    {   _target    = anEntity;
        _name    = aName;
        _source = someSource;
        _type    = FSRelationshipTypeToOne;
    }

    if(!_allRelationships) _allRelationships=[];
    _allRelationships.push(self);
    return self;

}
-(id) init
{   return [self initWithName: nil source: nil andTargetEntity: nil];
}
-(CPString) targetColumn
{   if(_targetColumn && _targetColumn.length) return _targetColumn;
    return [_target pk];
}
-(CPArray) fetchObjectsForKey:(id) targetPK options: myOptions
{   if(!targetPK) return nil;
    var peek;
    if(!_target_cache) _target_cache=[];
    if(peek=_target_cache[targetPK]) return peek;
    var res= [[_target store] fetchObjectsWithKey: [self targetColumn] equallingValue: targetPK inEntity: _target options: myOptions];
    _target_cache[targetPK]=res;
    return res;
}
-(CPArray) fetchObjectsForKey:(id) targetPK
{   var myoptions=[CPDictionary dictionaryWithObject: "0" forKey: "FSSynchronous"];
    return [self fetchObjectsForKey: targetPK options: myoptions];
}

-(void) _invalidateCache
{   _target_cache=[];
    [_target _invalidatePKCache];
}

+(CPArray) relationshipsWithTargetEntity:(FSEntity) anEntity
{   var ret=[];
    var i,l= _allRelationships.length;
    for(i=0;i<l;i++)
    {   var r= _allRelationships[i];
        if(r._target === anEntity) ret.push(r);
    }
    return ret;
}

@end


@implementation FSObject : CPObject 
{   CPMutableDictionary _data;
    CPMutableDictionary _changes;
    CPMutableDictionary _formatters;
    FSEntity _entity @accessors(property=entity);
}

-(id) initWithEntity:(id) anEntity
{   self = [super init];
    if (self)
    {   _entity=anEntity;
    }
    return self;
}

-(void) reload
{   var mypk=[self valueForKey: [[self entity] pk] synchronous:YES];
    if([self entity]._pkcache)   [self entity]._pkcache[mypk]=undefined;
    var tmpbj= [[self entity] objectWithPK: mypk];
    if(!tmpbj) return;
    var cols=[tmpbj._data allKeys];
    var i,l=[cols count];
    for(i=0; i<l; i++)
    {   var aKey = [cols objectAtIndex:i];
        if([_data objectForKey: aKey] !== [tmpbj._data objectForKey: aKey])
        {   [self willChangeValueForKey:aKey];
            [_data setObject: [tmpbj._data objectForKey: aKey] forKey: aKey];
            if(_changes) [_changes removeObjectForKey: aKey];
            [self didChangeValueForKey:aKey];
        }
    }
}

- (void)_setDataFromJSONObject:(id) o
{   _data = [CPMutableDictionary dictionary];
    var cols=[[_entity columns] allObjects];
    var i,l=cols.length;
    for(i=0; i<l; i++)
    {   var propName = cols[i];

        if(o[propName] !== nil)
            [_data setObject: o[propName] forKey:propName];
   }
}

-(void) setFormatter: (CPFormatter) aFormatter forColumnName:(CPString) aName
{   if(!_formatters) _formatters=[CPMutableDictionary new];
    [_formatters setObject:aFormatter forKey: aName];
}
-(CPFormatter) formatterForColumnName:(CPString) aName
{   if(!_formatters) return nil;
    return [_formatters objectForKey: aName];
}

- (id)dictionary
{   var o=[_data copy];
    if(!o) o=[CPMutableDictionary new];
    if(_changes) [o addEntriesFromDictionary: _changes];
    return o;
}
- (id)description
{
    return [[self dictionary] description];
}

-(int) typeOfKey:(CPString)aKey
{   if( [[_entity columns] containsObject: aKey]) return 0;
    if( [_entity relationOfName: aKey]) return 1;
    return CPNotFound;
}

- (id)valueForKey:(CPString)aKey synchronous:(BOOL) runSynced
{   var type= [self typeOfKey: aKey];

    if(type == 0)
    {   if(!_data)        // <!>fixme: implement lazy (batch-) fetching here
        {
        }
    
        var  o= [([_changes containsKey: aKey]? _changes:_data) objectForKey: aKey];
        var peek=[self formatterForColumnName:aKey];
        if(peek || (peek=[_entity formatterForColumnName:aKey]))
        {   return [peek objectValueForString: o error: nil];    //<!> fixme handle errors somehow
        } else if([_entity  isNumericColumn:aKey]) return [CPNumber numberWithInt:parseInt(o, 10)];
        else if (o)
        {   if(![o isKindOfClass:[CPString class]])    // cast numbers to strings in order to make predicate filtering work
                 o=[o stringValue];
        }
        return o;
    } else if(type == 1)    // a relationship is accessed
    {   var rel=[_entity relationOfName: aKey];
        var bindingColumn=[rel bindingColumn];
        if(!bindingColumn) bindingColumn=[_entity pk];

        var isToMany=([rel type]== FSRelationshipTypeToMany);
        var myoptions=[CPMutableDictionary new];
        if([rel type]== FSRelationshipTypeFuzzy)
        {   isToMany=YES;
            [myoptions setObject:"1" forKey:"FSFuzzySearch"];
        }
        if(!isToMany || runSynced || [rel runSynced]) [myoptions setObject:"1" forKey:"FSSynchronous"];
        var results=[rel fetchObjectsForKey: [self valueForKey: bindingColumn] options: myoptions];
        if(isToMany)
        {
            var defaults=rel._targetColumn? [CPDictionary dictionaryWithObject: [self valueForKey: bindingColumn] forKey: rel._targetColumn]:@{};
            [results setDefaults: defaults];
            [results setKvoKey: aKey];
            [results setKvoOwner: self];
            return results;
        } else return (results && [results count])? [results objectAtIndex: 0] : nil;
    } else
    {   var propSEL = sel_getName(aKey);
        if (propSEL && [self respondsToSelector: propSEL ]) return [self performSelector:propSEL];
        else [CPException raise:CPInvalidArgumentException reason:@"Key "+aKey+" is not a column in entity "+[_entity name]];
    }
}
- (id)valueForKey:(CPString)aKey
{   return [self valueForKey: aKey synchronous: NO];
}
- (void)setValue: someval forKey:(CPString)aKey
{   var type= [self typeOfKey:aKey];
    var oldval=[self valueForKey:aKey];

    if(oldval === someval) return;    // we are not interested in side effects, so ignore identity-updates

    if(type == 0)
    {   if(!_changes) _changes = [CPMutableDictionary dictionary];
        [self willChangeValueForKey:aKey];
        var peek=[self formatterForColumnName: aKey];

        if(peek || (peek=[_entity formatterForColumnName: aKey]))
            someval= [peek stringForObjectValue:someval];

        [_changes setObject: someval forKey: aKey];
        [self didChangeValueForKey:aKey];
        [[_entity store] writeChangesInObject:self];

        var allRels=[_entity._relations allObjects];
        if (allRels)
        {   var i,l= allRels.length;
            for(i=0; i<l; i++)
            {   var rel = allRels[i];
                rel._target_cache=[];
                var name = [rel name];
                [self willChangeValueForKey:name];
                [self didChangeValueForKey:name];
            }
        }
    } else if(type == 1)
    {   // this is only to make KVC upates happen in order to update the selection in the arraycontrollers.
    }
    else [CPException raise:CPInvalidArgumentException reason:@"Key "+aKey+" is not a column"];
}
- (id)valueForKeyPath:(CPString)aKeyPath
{
    var firstDotIndex = aKeyPath.indexOf(".");

    if (firstDotIndex === CPNotFound)
        return [self valueForKey:aKeyPath];

    var firstKeyComponent = aKeyPath.substring(0, firstDotIndex),
        remainingKeyPath = aKeyPath.substring(firstDotIndex + 1),
        value = [self valueForKey:firstKeyComponent synchronous: YES];

    return [value valueForKeyPath:remainingKeyPath];
}

@end

@implementation FSStore : CPObject 
{   CPString _baseURL @accessors(property=baseURL);
    unsigned _fetchLimit @accessors(property=fetchLimit);
}

-(CPURLRequest) requestForInsertingObjectInEntity:(FSEntity) someEntity
{   var request = [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+ [someEntity pk]];
    [request setHTTPMethod:"POST"];
    return request;
}
-(CPURLRequest) requestForAddressingObjectsWithKey:(CPString)aKey equallingValue: (id) someval inEntity:(FSEntity) someEntity
{   var request = [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+aKey+"/"+encodeURIComponent(someval)];
    return request;
}
-(CPURLRequest) requestForFuzzilyAddressingObjectsWithKey:(CPString)aKey equallingValue:(id) someval inEntity:(FSEntity)someEntity
{   var request = [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name]+"/"+aKey+"/like/"+encodeURIComponent(someval)];
    return request;
}
-(CPURLRequest) requestForAddressingAllObjectsInEntity:(FSEntity) someEntity
{
// alert([self baseURL]+"/"+[someEntity name])
    return [CPURLRequest requestWithURL: [self baseURL]+"/"+[someEntity name] ];
}

-(id) initWithBaseURL:(CPString) someURL
{   self = [super init];
    if (self)
    {   _baseURL = someURL;
    }
    return self;
}

-(CPArray) fetchObjectsForURLRequest:(CPURLRequest) request inEntity: (FSEntity) someEntity requestDelegate: someDelegate
{   if(someDelegate)
    {   [CPURLConnection connectionWithRequest:request delegate:someDelegate];
        return someDelegate;
    }
    var data=[CPURLConnection sendSynchronousRequest: request returningResponse: nil];
    var j = JSON.parse( [data rawString]);
    var a=[CPMutableArray new];
    if(j)
    {   var i,l=j.length;
        for(i=0;i<l;i++)
        {   var pk=j[i][[someEntity pk]];
            var peek;
            if (peek=[someEntity _registeredObjectForPK: pk])    // enforce singleton pattern
            {   [a addObject:peek];

            } else
            {   var t=[[FSObject alloc] initWithEntity: someEntity];
                [t _setDataFromJSONObject: j[i] ];
                [someEntity _registerObjectInPKCache: t];
                [a addObject:t];
            }
        }
    }
    return [[FSMutableArray alloc] initWithArray: a ofEntity: someEntity];
}




-(CPArray) fetchAllObjectsInEntity:(FSEntity) someEntity
{   return [self fetchObjectsForURLRequest: [self requestForAddressingAllObjectsInEntity: someEntity] inEntity:someEntity requestDelegate: nil];
}

// CRUD combo

-(id) fetchObjectsWithKey: aKey equallingValue: (id) someval inEntity:(FSEntity) someEntity options: myOptions
{   if( aKey == [someEntity pk] ) 
    {   var peek;
        if(peek=[someEntity _registeredObjectForPK: someval]) return [CPArray arrayWithObject: peek];
    }
    var request;
    if(myOptions && parseInt([myOptions objectForKey: "FSFuzzySearch"], 10))
         request=[self requestForFuzzilyAddressingObjectsWithKey: aKey equallingValue: someval inEntity: someEntity];
    else request=[self requestForAddressingObjectsWithKey: aKey equallingValue: someval inEntity: someEntity];
    var a=nil;
    if(!(myOptions && parseInt([myOptions objectForKey:"FSSynchronous"], 10)))
    {   a=[[FSMutableArray alloc] initWithArray: [] ofEntity: someEntity];
        if(someEntity.__ACForSpinner && someEntity.__ACForSpinner.__tableViewForSpinner)
            [someEntity.__ACForSpinner.__tableViewForSpinner _startAnimation: self];
    }
    return [self fetchObjectsForURLRequest: request inEntity: someEntity requestDelegate: a];
}

-(void) writeChangesInObject: (id) obj
{   var mypk=[obj valueForKey: [[obj entity] pk]];
    if([[obj entity] pk] === undefined) return;
    if(!obj._changes) return;
    var request=[self requestForAddressingObjectsWithKey: [[obj entity] pk] equallingValue: mypk inEntity:[obj entity]];
    [request setHTTPMethod:"PUT"];
    [request setHTTPBody: [obj._changes toJSON] ];
    var ret=[CPURLConnection sendSynchronousRequest:request returningResponse: nil];
    try{
    var err = JSON.parse( [ret rawString] );
    } catch(e)
    {
    }
    if(err && err['err'])
    {   alert(err['err']);
        obj._changes=nil;  // discard changes that weren't accepted by the backend
    }

    [obj reload];
}

-(void) insertObject:(id)someObj 
{   var entity=[someObj entity];
    var request=[self requestForInsertingObjectInEntity:entity];
    [request setHTTPBody:[someObj._changes toJSON] ];
    var data=[CPURLConnection sendSynchronousRequest: request returningResponse: nil];
    var j = JSON.parse( [data rawString]);    // this is necessary for retrieving the PK
    var pk=j["pk"];
    [someObj willChangeValueForKey: [entity pk]];
    if(!someObj._data) someObj._data=[CPMutableDictionary new];
    [someObj._data setObject: pk forKey: [entity pk]];
    [entity _registerObjectInPKCache:someObj];
    [someObj didChangeValueForKey: [entity pk]];
}

- (void)deleteObject:(id)obj
{
    var request=[self requestForAddressingObjectsWithKey:[[obj entity] pk] equallingValue: [obj valueForKey: [[obj entity] pk]] inEntity:[obj entity]];
    [request setHTTPMethod:"DELETE"];
    //[CPURLConnection sendSynchronousRequest:request returningResponse: nil];
    [CPURLConnection connectionWithRequest:request delegate:nil];
}

@end
