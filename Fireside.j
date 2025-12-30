/*
 * Fireside: Modernized & PubSub Enabled
 * Transparent Live-Sync Edition
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>
@import <Foundation/CPURLRequest.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPOperationQueue.j>
@import "FSMutableArray.j"

// MARK: - Utilities

@implementation CPNull (FSFix)
- (CPString)stringValue { return "NULL"; }
@end

@implementation CPArray (AllObjects)
- (CPArray)allObjects { return self; }
@end

@implementation CPString (DataFix)
- (CPString)rawString { return self; }
@end

@implementation CPDictionary (JSONExport)
- (CPString)toJSON
{
    var keys = [self allKeys],
    l = keys.length,
    o = {},
    nullObj = [CPNull null];

    for (var i = 0; i < l; i++)
    {
        var key = keys[i],
        val = [self objectForKey:key];
        o[key] = (val === nullObj) ? null : val;
    }

    return JSON.stringify(o);
}
@end

// MARK: - Forward Declarations & Constants

var FSRelationshipTypeToOne = 0;
var FSRelationshipTypeToMany = 1;
var FSRelationshipTypeFuzzy = 2;

@class FSStore
@class FSObject

// MARK: - FSEntity

@implementation FSEntity : CPObject
{
    CPString            _name @accessors(property=name);
    CPString            _pk @accessors(property=pk);
    CPSet               _columns @accessors(property=columns);
    CPSet               _relations;
    CPSet               _numerics;
    CPSet               _optimistics;
    FSStore             _store @accessors(property=store);
    CPMutableArray      _pkcache;
    CPMutableDictionary _formatters;
    id                  _delegate @accessors(property=delegate);

    // Live Sync Tracking
    Array               _liveArrays;
}

- (id)initWithName:(CPString)aName andStore:(FSStore)someStore
{
    self = [super init];

    if (self)
    {
        _store = someStore;
        _name = aName;
        _pkcache = [];
        _relations = [CPSet set];
        _numerics = [CPSet set];
        _optimistics = [CPSet set];
        _liveArrays = [];
    }
    return self;
}

- (id)init
{
    return [self initWithName:nil andStore:nil];
}

- (FSEntity)copyOfEntity
{
    var other = [[FSEntity alloc] init];
    other._name = _name;
    other._pk = _pk;
    other._columns = _columns;
    other._relations = _relations;
    other._numerics = _numerics;
    other._store = _store;
    other._pkcache = _pkcache;
    other._formatters = _formatters;
    other._optimistics = _optimistics;
    other._liveArrays = []; // Do not copy live arrays

    return other;
}

// Relationships

- (FSRelationship)relationshipWithTarget:(CPString)targetEntityName
{
    var rels = [_relations allObjects];
    for (var i = 0; i < [rels count]; i++)
    {
        var r = rels[i], target = [r target];
        if (target && [[target name] isEqualToString:targetEntityName]) return r;
    }
    return nil;
}

- (FSRelationship)relationshipWithName:(CPString)aName
{
    var rels = [_relations allObjects];
    for(var i = 0; i < [rels count]; i++)
    {
        var r = rels[i];
        if([r name] == aName) return r;
    }
    return nil;
}

- (void)addRelationship:(FSRelationship)someRel
{
    [_relations addObject:someRel];
}

- (void)setRelationship:(FSRelationship)aRel forTarget:(CPString)aTarget
{
    var existingRel = [self relationshipWithTarget:aTarget];
    if (existingRel) [_relations removeObject:existingRel];
    [_relations addObject:aRel];
}

- (CPArray)relationshipsWithTargetProperty:(CPString)aKey
{
    var ret = [CPMutableArray array], rels = [_relations allObjects];
    if (!rels) return ret;
    for (var i = 0; i < [rels count]; i++)
    {
        var r = rels[i];
        if ([r targetColumn] === aKey) [ret addObject:r];
    }
    return ret;
}

- (CPArray)relationshipsWithSourceProperty:(CPString)aKey
{
    var ret = [CPMutableArray array], rels = [_relations allObjects];
    if (!rels) return ret;
    for (var i = 0; i < [rels count]; i++)
    {
        var r = rels[i];
        if ([r bindingColumn] === aKey) [ret addObject:r];
    }
    return ret;
}

- (FSMutableArray)_arrayForArray:(CPArray)results withDefaults:(CPDictionary)someDefaults
{
    var r = [[FSMutableArray alloc] initWithArray:results ofEntity:self];
    if ([r respondsToSelector:@selector(setDefaults:)]) [r setDefaults:someDefaults];
    return r;
}

- (CPArray)relationships
{
    return [_relations allObjects];
}

// Columns & Formatting

- (void)addNumericColumn:(CPString)aCol { [_numerics addObject:aCol]; }
- (BOOL)isNumericColumn:(CPString)aCol { return [_numerics containsObject:aCol]; }
- (void)addOptimisticColumn:(CPString)aCol { [_optimistics addObject:aCol]; }
- (BOOL)isOptimisticColumn:(CPString)aCol { return [_optimistics containsObject:aCol]; }

- (void)setFormatter:(CPFormatter)aFormatter forColumnName:(CPString)aName
{
    if(!_formatters) _formatters = [CPMutableDictionary dictionary];
    [_formatters setObject:aFormatter forKey:aName];
}

- (CPFormatter)formatterForColumnName:(CPString)aName
{
    return [_formatters objectForKey:aName];
}

// Object Management

- (id)createObject
{
    return [self createObjectWithDictionary:nil];
}

- (id)createObjectWithDictionary:(CPDictionary)myDict
{
    var r = [[FSObject alloc] initWithEntity:self];
    if (myDict)
    {
        r._changes = [myDict copy];
        var allKeys = [myDict allKeys];
        for (var i = 0; i < [allKeys count]; i++)
        {
            var aKey = [allKeys objectAtIndex:i], formatter = [self formatterForColumnName:aKey];
            if (formatter) [r._changes setObject:[formatter stringForObjectValue:[myDict objectForKey:aKey]] forKey:aKey];
        }
    }
    return r;
}

- (FSObject)insertObject:(id)someObj
{
    if([someObj isKindOfClass:[CPDictionary class]]) someObj = [self createObjectWithDictionary:someObj];
    [_store insertObject:someObj];
    return someObj;
}

- (void)deleteObject:(id)someObj
{
    [_store deleteObject:someObj];
}

- (id)objectWithPK:(id)somePK
{
    var myoptions = [CPDictionary dictionaryWithObject:"1" forKey:"FSSynchronous"];
    var a = [[self store] fetchObjectsWithKey:[self pk] equallingValue:somePK inEntity:self options:myoptions];
    if([a count] == 1) return [a objectAtIndex:0];
    return nil;
}

- (CPArray)allObjects
{
    return [_store fetchAllObjectsInEntity:self];
}

// Cache Internals

- (void)_registerObjectInPKCache:(id)someObj
{
    if (!_pkcache) _pkcache = [];
    if(_pk) _pkcache[someObj._data.valueForKey(_pk)] = someObj;
}

- (id)_registeredObjectForPK:(id)somePK
{
    if (!_pkcache)
        return nil;

    return _pkcache[somePK];
}

- (void)_invalidatePKCache
{
    _pkcache = [];
}


// MARK: - Transparent Live Sync

/*
 * Tracks a CPArray so that we can push WebSocket updates to it automatically.
 * Uses WeakRef to avoid memory leaks since FSEntity lives forever.
 */
- (void)_registerLiveArray:(CPArray)anArray withMatcher:(Function)matcher
{
    if (!_liveArrays) _liveArrays = [];

    // Check for WeakRef support (Modern browsers/environments)
    var ref = (typeof WeakRef !== 'undefined') ? new WeakRef(anArray) : { deref: function(){ return anArray; }, isStrong: true };

    _liveArrays.push({
        ref: ref,
        matcher: matcher
    });
}

/*
 * Called by FSStore when a Push Notification arrives.
 * Updates all tracked arrays.
 */
- (void)_applyRemoteChange:(CPString)type object:(id)object
{
    if (!_liveArrays || _liveArrays.length === 0) return;

    var activeArrays = [];

    for (var i = 0; i < _liveArrays.length; i++)
    {
        var entry = _liveArrays[i];
        var arr = entry.ref.deref();

        // If array was collected, drop it (unless we are forced to keep strong refs)
        if (arr)
        {
            activeArrays.push(entry);

            try
            {
                if (type === "INSERT")
                {
                    // Check if object belongs in this array based on criteria
                    if (entry.matcher && entry.matcher(object))
                    {
                        // Prevent duplicates
                        if (![arr containsObject:object])
                            [arr addObject:object];
                    }
                }
                else if (type === "DELETE")
                {
                    // removeObject works because we use singleton FSObjects
                    [arr removeObject:object];
                }
            }
            catch (e) { console.error("Error applying remote change to array: " + e); }
        }
    }

    _liveArrays = activeArrays;
}

@end


// MARK: - FSRelationship

var _allRelationships;

@implementation FSRelationship : CPObject
{
    CPString    _name @accessors(property=name);
    FSEntity    _source @accessors(property=source);
    FSEntity    _target @accessors(property=target);
    CPString    _bindingColumn @accessors(property=bindingColumn);
    CPString    _targetColumn @accessors(setter=setTargetColumn:);
    int         _type @accessors(property=type);
    CPMutableArray _target_cache;
    BOOL        _runSynced @accessors(property=runSynced);
}

- (id)initWithName:(CPString)aName source:someSource andTargetEntity:(FSEntity)anEntity
{
    self = [super init];
    if (self)
    {
        _target = anEntity;
        _name = aName;
        _source = someSource;
        _type = FSRelationshipTypeToOne;
        _target_cache = [];
    }

    if(!_allRelationships) _allRelationships = [];
    _allRelationships.push(self);

    return self;
}

- (CPString)targetColumn
{
    if(_targetColumn && [_targetColumn length]) return _targetColumn;
    return [_target pk];
}

- (CPArray)fetchObjectsForKey:(id)targetPK options:(CPDictionary)myOptions
{
    if(!targetPK) return nil;
    if(!_target_cache) _target_cache = [];

    var cached = _target_cache[targetPK];
    if(cached) return cached;

    var res = [[_target store] fetchObjectsWithKey:[self targetColumn] equallingValue:targetPK inEntity:_target options:myOptions];
    _target_cache[targetPK] = res;

    return res;
}

- (CPArray)fetchObjectsForKey:(id)targetPK
{
    var myoptions = [CPDictionary dictionaryWithObject:"0" forKey:"FSSynchronous"];
    return [self fetchObjectsForKey:targetPK options:myoptions];
}

- (void)_invalidateCache
{
    _target_cache = [];
    [_target _invalidatePKCache];
}

+ (CPArray)relationshipsWithTargetEntity:(FSEntity)anEntity
{
    var ret = [CPMutableArray array];
    var l = _allRelationships.length;
    for (var i = 0; i < l; i++)
    {
        var r = _allRelationships[i];
        if ([r target] === anEntity) [ret addObject:r];
    }
    return ret;
}
@end


// MARK: - FSStore (Modernized + Compatible)

@implementation FSStore : CPObject
{
    CPString            _baseURL @accessors(property=baseURL);
    CPOperationQueue    _persistenceQueue;
    id                  _webSocket;
    CPMutableDictionary _registeredEntities;
}

- (id)initWithBaseURL:(CPString)someURL
{
    self = [super init];
    if (self)
    {
        _baseURL = someURL;
        _registeredEntities = [CPMutableDictionary dictionary];
        _persistenceQueue = [[CPOperationQueue alloc] init];
        [self _connectWebSocket];
    }
    return self;
}

- (void)registerEntity:(FSEntity)anEntity
{
    [_registeredEntities setObject:anEntity forKey:[anEntity name]];
}

// WebSocket Live Sync

- (void)_connectWebSocket
{
    var wsURL = _baseURL.replace("http", "ws") + "/socket";
    if (window.G_SESSION) wsURL += "?session=" + window.G_SESSION;

    _webSocket = new WebSocket(wsURL);
    _webSocket.onmessage = function(evt) { [self _handlePushNotification:evt.data]; };
    _webSocket.onclose = function() { window.setTimeout(function(){ [self _connectWebSocket]; }, 5000); };
}

- (void)_handlePushNotification:(CPString)jsonString
{
    try
    {
        var payload = JSON.parse(jsonString);
        var entity = [_registeredEntities objectForKey:payload.table];

        if (!entity)
           return;

        var object = [entity _registeredObjectForPK:payload.pk];
        
        // 1. Handle DELETE (Simple, no fetching needed)
        if (payload.type === "DELETE")
        {
            if (object)
            {
                [entity _applyRemoteChange:"DELETE" object:object];
                entity._pkcache[payload.pk] = undefined;
            }
            return;
        }

        // 2. Handle INSERT / UPDATE (Partial Apply)
        
        // If it's an INSERT and we don't have it, create the skeleton immediately
        // so the UI updates (e.g. the row appears in the table with just the Name)
        if (payload.type === "INSERT" && !object)
        {
            object = [[FSObject alloc] initWithEntity:entity];
            [object _setDataFromJSONObject:payload.data];
            [entity _registerObjectInPKCache:object];
            [entity _applyRemoteChange:"INSERT" object:object];
        }
        else if (object) // UPDATE
        {
            // Apply whatever data we received (partial updates)
            console.log("FSStore: Payload not truncated. refreshing PK: " + payload.pk);
            [object _refreshDataFromJSONObject:payload.data];
        }

        // 3. Handle Truncation (The "Out-of-Band" Fetch)
        if (payload.truncated)
        {
            // The server told us "I have more data, but it didn't fit."
            // We trigger a standard fetch for this specific object.
            // This will hit: GET /DB/manuscripts/id/123
            // The result will automatically merge into the singleton 'object' via _processJSON

            // force full refetch
            entity._pkcache[payload.pk] = undefined;

            [self fetchObjectsWithKey:[entity pk]
                       equallingValue:payload.pk 
                             inEntity:entity 
                              options:nil];

            console.log("FSStore: Payload truncated. Fetching full object out-of-band for PK: " + payload.pk);
        }
    }
    catch (e) { console.error(e); }
}

// Factories

- (CPURLRequest)requestForInsertingObjectInEntity:(FSEntity)e
{
    [self registerEntity:e];
    var r = [CPURLRequest requestWithURL:_baseURL+"/"+[e name]+"/"+[e pk]];
    [r setHTTPMethod:"POST"];
    return r;
}

- (CPURLRequest)requestForUpdatingObject:(FSObject)o
{
    var e = [o entity];
    [self registerEntity:e];
    var r = [CPURLRequest requestWithURL:_baseURL+"/"+[e name]+"/"+[e pk]+"/"+encodeURIComponent([o valueForKey:[e pk]])];
    [r setHTTPMethod:"PATCH"];
    return r;
}

- (CPURLRequest)requestForDeletingObject:(FSObject)o
{
    var e = [o entity];
    var r = [CPURLRequest requestWithURL:_baseURL+"/"+[e name]+"/"+[e pk]+"/"+encodeURIComponent([o valueForKey:[e pk]])];
    [r setHTTPMethod:"DELETE"];
    return r;
}

// Writes (Serial Queue)

- (void)insertObject:(id)obj
{
    if(!obj._changes) return;
    var req = [self requestForInsertingObjectInEntity:[obj entity]];
    [req setHTTPBody:[obj._changes toJSON]];
    [_persistenceQueue addOperation:[[FSRequestOperation alloc] initWithRequest:req object:obj type:"INSERT"]];
}

- (void)writeChangesInObject:(id)obj
{
    if(![obj._changes count]) return;
    var req = [self requestForUpdatingObject:obj];
    [req setHTTPBody:[obj._changes toJSON]];
    [_persistenceQueue addOperation:[[FSRequestOperation alloc] initWithRequest:req object:obj type:"UPDATE"]];
}

- (void)deleteObject:(id)obj
{
    var req = [self requestForDeletingObject:obj];
    [_persistenceQueue addOperation:[[FSRequestOperation alloc] initWithRequest:req object:obj type:"DELETE"]];
}

// Reads (Async + Sync Compatibility + Live Tracking)

- (id)fetchObjectsWithKey:(CPString)aKey equallingValue:(id)someVal inEntity:(FSEntity)someEntity options:(CPDictionary)myOptions
{
    [self registerEntity:someEntity];

    if(aKey == [someEntity pk])
    {
        var peek = [someEntity _registeredObjectForPK:someVal];

        if (peek)
            return [CPArray arrayWithObject:peek];
    }

    var isFuzzy = (myOptions && [myOptions objectForKey:"FSFuzzySearch"]);
    var urlStr = _baseURL + "/" + [someEntity name] + "/" + aKey + (isFuzzy ? "/like/" : "/") + encodeURIComponent(someVal);
    var request = [CPURLRequest requestWithURL:urlStr];

    // Define Matcher for this fetch
    var matcher = function(candidateObj) {
        if (aKey === "1" && someVal === "1") return true; // All Objects
        var val = [candidateObj valueForKey:aKey];
        // Loose equality (to match "1" with 1)
        return val == someVal;
    };

    // --- Synchronous Path ---
    if(myOptions && parseInt([myOptions objectForKey:"FSSynchronous"], 10))
    {
        var data = [CPURLConnection sendSynchronousRequest:request returningResponse:nil];
        if (!data) return nil;
        var json = JSON.parse([data rawString]);
        var resArray = [CPMutableArray array];
        for(var i = 0; i<json.length; i++) {
            [resArray addObject:[self _processJSON:json[i] forEntity:someEntity]];
        }
        var finalArr = [[FSMutableArray alloc] initWithArray:resArray ofEntity:someEntity];

        // AUTO-TRACKING
        [someEntity _registerLiveArray:finalArr withMatcher:matcher];

        return finalArr;
    }

    // --- Asynchronous Path ---
    var resultArray = [[FSMutableArray alloc] initWithArray:@[] ofEntity:someEntity];

    // AUTO-TRACKING immediately (it will populate later, but we track the instance)
    [someEntity _registerLiveArray:resultArray withMatcher:matcher];

    [CPURLConnection sendAsynchronousRequest:request queue:[CPOperationQueue mainQueue] completionHandler:function(resp, data, err)
     {
        if(err || !data) return;

        var json = JSON.parse([data rawString]);
        var objects = [];

        for(var i = 0; i < json.length; i++)
        {
            [objects addObject:[self _processJSON:json[i] forEntity:someEntity]];
        }

        [resultArray addObjectsFromArray:objects];

        if (someEntity.__ACForSpinner)
            [someEntity.__ACForSpinner setContent:resultArray];
    }];

    return resultArray;
}

- (id)_processJSON:(Object)row forEntity:(FSEntity)entity
{
    var pk = row[[entity pk]];
    var obj = [entity _registeredObjectForPK:pk];
    if(!obj) {
        obj = [[FSObject alloc] initWithEntity:entity];
        [obj _setDataFromJSONObject:row];
        [entity _registerObjectInPKCache:obj];
    } else {
        [obj _refreshDataFromJSONObject:row];
    }
    return obj;
}

- (CPArray)fetchAllObjectsInEntity:(FSEntity)e
{
    return [self fetchObjectsWithKey:@"1" equallingValue:@"1" inEntity:e options:nil];
}


- (CPArray)fetchObjectsForURLRequest:(CPURLRequest)request inEntity:(FSEntity)someEntity requestDelegate:(id)someDelegate
{
    [self registerEntity:someEntity];

    // --- Asynchronous Path (Delegate) ---
    if (someDelegate)
    {
        // Try to hook into the delegate if it's an array for Live Sync
        if ([someDelegate isKindOfClass:[CPArray class]])
        {
            // Heuristic: If we are fetching all objects via fullyReloadAsync, the URL usually
            // matches the pattern for "All Objects". If not, we fall back to a "permissive" matcher
            // or we try to parse the URL. For simplicity in the use case:
            // Assume if it's a delegate-based fetch on the entity root, it's ALL.

            var urlStr = [[request URL] absoluteString];
            // Basic matcher: accepts everything if we can't parse strictly.
            // Or assume "1"=="1" if the URL ends with the entity name.

            var matcher = function(candidate) { return true; }; // Default to accepting all insertions for delegate arrays

            [someEntity _registerLiveArray:someDelegate withMatcher:matcher];
        }

        [CPURLConnection connectionWithRequest:request delegate:someDelegate];
        return someDelegate;
    }

    // --- Synchronous Path ---
    var data = [CPURLConnection sendSynchronousRequest:request returningResponse:nil];
    if (!data) return [[FSMutableArray alloc] initWithArray:@[] ofEntity:someEntity];

    try
    {
        var json = JSON.parse([data rawString]);
        var results = [CPMutableArray array];

        if (json && json.length)
        {
            for (var i = 0; i < json.length; i++)
                [results addObject:[self _processJSON:json[i] forEntity:someEntity]];
        }

        var finalArr = [[FSMutableArray alloc] initWithArray:results ofEntity:someEntity];
        // Track Sync URL requests as "All/Permissive"
        [someEntity _registerLiveArray:finalArr withMatcher:function(){return true;}];

        return finalArr;
    }
    catch (e)
    {
        console.error("Failed to parse JSON: " + e);
        return [[FSMutableArray alloc] initWithArray:@[] ofEntity:someEntity];
    }
}

@end


// MARK: - FSRequestOperation

@implementation FSRequestOperation : CPOperation
{
    CPURLRequest    _req;
    id              _obj;
    CPString        _type;
    BOOL            _opExecuting;
    BOOL            _opFinished;
    CPString        _data;
}

- (id)initWithRequest:(CPURLRequest)r object:(id)o type:(CPString)t
{
    self = [super init];
    if(self)
    {
        _req = r;
        _obj = o;
        _type = t;
        _opExecuting = NO;
        _opFinished = NO;
    }
    return self;
}

- (void)start
{
    if([self isCancelled]) { [self finish]; return; }
    [self willChangeValueForKey:@"isExecuting"];
    _opExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [CPURLConnection connectionWithRequest:_req delegate:self];
}

- (BOOL)isConcurrent { return YES; }
- (BOOL)isExecuting { return _opExecuting; }
- (BOOL)isFinished { return _opFinished; }

- (void)connection:(CPURLConnection)c didReceiveData:(CPString)d
{
    if(!_data) _data = "";
    _data += d;
}

- (void)connectionDidFinishLoading:(CPURLConnection)c
{
    try {
        var json = JSON.parse(_data);
        if (json.err) {
            console.error("Error " + _type + ": " + json.err);
        }
        else if (_type === "INSERT" && json.pk) {
            var e = [_obj entity];
            [_obj willChangeValueForKey:[e pk]];
            [_obj._data setObject:json.pk forKey:[e pk]];
            [e _registerObjectInPKCache:_obj];
            [_obj didChangeValueForKey:[e pk]];
            _obj._changes = nil;
        }
        else if (_type === "UPDATE") {
            var changedKeys = [_obj._changes allKeys], count = [changedKeys count];
            for (var i = 0; i < count; i++) {
                var key = changedKeys[i], val = [_obj._changes objectForKey:key];
                if (json && json[key] !== undefined) val = json[key];
                [_obj willChangeValueForKey:key];
                [_obj._data setObject:val forKey:key];
                [_obj didChangeValueForKey:key];
            }
            _obj._changes = nil;

            if (json)
                [_obj _refreshDataFromJSONObject:json];
        }
    } catch(e) { console.error("JSON Error: " + e); }
    [self finish];
}
- (void)connection:(CPURLConnection)c didFailWithError:(id)e
{
    console.error("Connection Failed: " + e);
    [self finish];
}
- (void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _opExecuting = NO;
    _opFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end

// MARK: - FSObject

@implementation FSObject : CPObject
{
    CPMutableDictionary _data;
    CPMutableDictionary _changes @accessors(property=changes);
    CPMutableDictionary _formatters;
    FSEntity            _entity @accessors(property=entity);
}

- (id)initWithEntity:(id)anEntity
{
    self = [super init];
    if (self)
    {
        _entity = anEntity;
        _data = [CPMutableDictionary dictionary];
    }
    return self;
}

- (void)reload
{
    var pk = [_data objectForKey:_entity._pk];

    if (_entity._pkcache) _entity._pkcache[pk] = undefined;
    var fresh = [_entity objectWithPK:pk];

    if(fresh) [self _refreshDataFromJSONObject:fresh._data];
}

- (void)_refreshDataFromJSONObject:(id)o
{
    for (var propName in o)
    {
        if (o.hasOwnProperty(propName))
        {
            var pnv = o[propName];

            console.log("PNV: "+pnv);

            if(pnv !== nil && ![pnv isEqual:[_data objectForKey:propName]])
            {
                [self willChangeValueForKey:propName];
                [_data setObject:pnv forKey:propName];
                [self didChangeValueForKey:propName];
            }
        }
    }
}

- (void)_setDataFromJSONObject:(id)o
{
    _data = [CPMutableDictionary dictionary];
    for (var propName in o)
        if (o.hasOwnProperty(propName) && o[propName] !== nil) _data.setValueForKey(propName, o[propName]);
}

- (id)dictionary
{
    var o = [_data copy];
    if(_changes) [o addEntriesFromDictionary:_changes];
    return o;
}

- (int)typeOfKey:(CPString)aKey
{
    if( [[_entity columns] containsObject:aKey]) return 0;
    if( [_entity relationOfName:aKey]) return 1;
    return CPNotFound;
}

- (id)valueForKey:(CPString)aKey synchronous:(BOOL)runSynced
{
    var type = [self typeOfKey:aKey];

    if(type == 0)
    {
        var o = ([_changes objectForKey:aKey]) ? [_changes objectForKey:aKey] : [_data objectForKey:aKey];
        var formatter = [self formatterForColumnName:aKey] || [_entity formatterForColumnName:aKey];
        if(formatter) return [formatter objectValueForString:o error:nil];
        if([_entity isNumericColumn:aKey]) return [CPNumber numberWithInt:parseInt(o, 10)];
        if (o && ![o isKindOfClass:[CPString class]]) {
            if([o isKindOfClass:[CPArray class]] && [o count]) o = o[0];
            if([o respondsToSelector:@selector(stringValue)]) o = [o stringValue];
        }
        return o;
    }
    else if(type == 1)
    {
        var rel = [_entity relationOfName:aKey];
        var bindingColumn = [rel bindingColumn] || [_entity pk];
        var isToMany = ([rel type] == FSRelationshipTypeToMany);
        var myoptions = [CPMutableDictionary dictionary];

        if ([rel type] == FSRelationshipTypeFuzzy) {
            isToMany = YES;
            [myoptions setObject:"1" forKey:"FSFuzzySearch"];
        }
        if (!isToMany || runSynced || [rel runSynced]) [myoptions setObject:"1" forKey:"FSSynchronous"];

        var results = [rel fetchObjectsForKey:[self valueForKey:bindingColumn] options:myoptions];
        if (isToMany) {
            var defaults = rel._targetColumn ? [CPDictionary dictionaryWithObject:[self valueForKey:bindingColumn] forKey:rel._targetColumn] : @{};
            if([results respondsToSelector:@selector(setDefaults:)]) [results setDefaults:defaults];
            if([results respondsToSelector:@selector(setKvoKey:)]) { [results setKvoKey:aKey]; [results setKvoOwner:self]; }
            return results;
        }
        else return (results && [results count]) ? [results objectAtIndex:0] : nil;
    }
    else
    {
        var propSEL = sel_getName(aKey);
        if (propSEL && [self respondsToSelector:propSEL]) return [self performSelector:propSEL];
        if (_entity._delegate && [_entity._delegate respondsToSelector:@selector(entity:valueForKey:synchronous:)])
            return [_entity._delegate entity:_entity valueForKey:aKey synchronous:runSynced];
        console.log("Key "+aKey+" is not a column in entity "+[_entity name]);
    }
    return nil;
}

- (id)valueForKey:(CPString)aKey { return [self valueForKey:aKey synchronous:NO]; }

- (void)setValue:(id)someval forKey:(CPString)aKey
{
    if (someval === nil) return;
    var currentVal = [self valueForKey:aKey];
    if (currentVal === someval) return;
    var type = [self typeOfKey:aKey];

    if(type == 0)
    {
        if(!_changes) _changes = [CPMutableDictionary dictionary];
        [self willChangeValueForKey:aKey];
        var formatter = [self formatterForColumnName:aKey] || [_entity formatterForColumnName:aKey];
        if(formatter) someval = [formatter stringForObjectValue:someval];
        [_changes setObject:someval forKey:aKey];
        [self didChangeValueForKey:aKey];

        [[_entity store] writeChangesInObject:self];

        if (![_entity isOptimisticColumn:aKey]) {
            var allRels = [_entity relationships];
            for(var i = 0; i<[allRels count]; i++) {
                var rel = allRels[i];
                [rel _invalidateCache];
                [self willChangeValueForKey:[rel name]];
                [self didChangeValueForKey:[rel name]];
            }
        }
    }
}

- (id)valueForKeyPath:(CPString)aKeyPath
{
    var firstDot = aKeyPath.indexOf(".");
    if (firstDot === CPNotFound) return [self valueForKey:aKeyPath];
    var first = aKeyPath.substring(0, firstDot);
    var rest = aKeyPath.substring(firstDot + 1);
    var val = [self valueForKey:first synchronous:YES];
    return [val valueForKeyPath:rest];
}

- (void)setFormatter:(CPFormatter)f forColumnName:(CPString)n
{
    if(!_formatters) _formatters=[CPMutableDictionary dictionary];
    [_formatters setObject:f forKey:n];
}

- (CPFormatter)formatterForColumnName:(CPString)n
{
    return [_formatters objectForKey:n];
}

@end
