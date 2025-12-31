# Cappusance

Cappusance is a powerful GUI builder for **Cappuccino** with strong autolayout capabilities. Cappusance is essentially a modern port of [GNUstep Renaissance](https://github.com/gnustep/libs-renaissance).

On top of the layout engine, Cappusance adds support for modern Cocoa controls, Cocoa bindings, and **Fireside**—a RESTful Object/Relational Mapper (ORM) with transparent Live Sync.

## Fireside: Modernized & Real-Time

Fireside brings the spirit of **EOF/WebObjects** to the browser. It automatically glues your database to the GUI with bidirectional bindings.

*   **Declarative:** Database entities map to `ArrayControllers`; relations are expressed as master-detail bindings.
*   **Transparent Live Sync:** Leveraging WebSockets and Postgres PubSub, changes made in one client are instantly reflected in all other connected clients without writing a single line of synchronization code.
*   **Zero Glue Code:** You can write a fully functional CRUD application with real-time collaboration capabilities just by defining XML.
*   **Undo/Redo:** `FSArrayController` supports `CPUndoManager` out of the box.

## Minimal Example

Here is how you build a collaborative "Manuscripts" editor in three steps.

### 1. Define the Model (`model.gsmarkup`)
Declaratively connect to your database entities. `FSArrayController` handles fetching, sorting, and synchronizing with the backend automatically.

```xml
<?xml version="1.0"?>
<!DOCTYPE gsmarkup>
<gsmarkup>
    <objects>
        <!-- Automatic Sort Descriptors -->
        <sortDescriptor id="time_sort" key="insertion_time" ascending="NO"/>

        <!-- The Controller: auto-fetches data and listens for WebSocket updates -->
        <arrayController id="manuscripts_controller" 
                         entity="manuscripts" 
                         autoFetch="YES" 
                         sortDescriptor="time_sort"/>
    </objects>

    <entities>
        <!-- Map directly to your Postgres table -->
        <entity id="manuscripts" store="#CPOwner.store">
            <column name="id" primaryKey="YES"/>
            <column name="name"/>
            <column name="content"/>
            <column name="insertion_time"/>
        </entity>
    </entities>

    <connectors>
        <!-- Hook the controller to your AppController -->
        <outlet source="#CPOwner" target="manuscripts_controller" label="manuscriptsController"/>
    </connectors>
</gsmarkup>
```

### 2. Build the Interface (`gui.gsmarkup`)
Build native-feeling interfaces using standard controls. Just bind the UI directly to the controller.

```xml
<?xml version="1.0"?>
<!DOCTYPE gsmarkup>
<gsmarkup>
    <objects>
        <window bridge="YES" id="mainwindow" delegate="#CPOwner">
             <vbox>
                 <!-- Master View: List of Manuscripts -->
                 <scrollView hasHorizontalScroller="NO">
                     <tableView zebra="yes" autosaveName="tv_manuscripts" id="tv_manuscripts" valueBinding="#CPOwner.manuscriptsController" allowsMultipleSelection="NO">
                         <tableColumn identifier="id" title="id"  editable="NO"/>
                         <tableColumn identifier="name" title="name"  editable="YES"/>
                         <tableColumn identifier="insertion_time" title="insertion_time"  editable="YES"/>
                     </tableView>
                 </scrollView>
                 
                <!-- Action Bar: Add/Remove handled by the controller -->
                <ButtonBar actionsButton="NO" target="#CPOwner.manuscriptsController" minusButtonAction="remove:"/>
                 
                <!-- Detail View: Text Editor -->
                <!-- Binds to the 'content' column of the currently selected row -->
                <scrollView hasHorizontalScroller="NO">
                     <textView editable="YES" valueBinding="#CPOwner.manuscriptsController.selection.content" backgroundColor="white"/>
                 </scrollView>
             </vbox>
        </window>
    </objects>

    <connectors>
        <outlet source="CPOwner" target="mainwindow" label="mainWindow"/>
        <outlet source="CPOwner" target="tv_manuscripts" label="manuscriptsTableView"/>
    </connectors>
</gsmarkup>
```

### 3. Connect the Logic (`AppController.j`)
Initialize the store. That's it. Fireside detects the entity, subscribes to the WebSocket channel, and keeps the UI in sync.

```objective-j
@import <Renaissance/Renaissance.j>

@implementation AppController : CPObject
{
    // Outlets connected via GSMarkup
    id manuscriptsController @accessors;
    id _store @accessors(property = store);
    
    id mainwindow;
    id manuscriptsTableView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // 1. Connect to the Backend
    _store = [[FSStore alloc] initWithBaseURL: "http://127.0.0.1:3000/DB"];

    // 2. Load the Model
    // Objects in markup can access this controller via '#CPOwner'
    [CPBundle loadRessourceNamed: "model.gsmarkup" owner:self];

    // 3. Load the GUI
    [CPBundle loadRessourceNamed: "gui.gsmarkup" owner:self];

    // There is no step 4. 
    // Data fetches automatically. Edits save automatically. 
    // Changes from other users appear instantly via WebSockets.
}
@end
```

### 4. The Backend (e.g. Mojo.js)
**[Mojo.js](https://mojojs.org/)** is a perfect match as this framework easily provides the REST API and the WebSocket stream. The following generic script handles CRUD and broadcasts updates to all connected clients. You could use this script with minimal modifications for all your projects. However, because Fireside is backend-agnostic any other backend will do.

```javascript
import mojo from '@mojojs/core';
import postgres from 'postgres';

const app = mojo();

// 1. Connect to Postgres
// We use the 'postgres' library which handles connection pooling automatically.
const sql = postgres('postgresql://postgres@localhost/name_of_your_postgres_database');

// Register a helper to access the DB easily in routes
app.decorateContext('sql', sql);

// 2. WebSocket Route for Live Sync
app.websocket('/DB/socket', async ctx => {
    // Increase timeout (Node uses milliseconds, so 3600 * 1000)
    ctx.req.socket.setTimeout(3600000);

    // Listen for PG notifications
    // postgres.js handles the dedicated connection for listening automatically
    const listener = await ctx.sql.listen('fireside_updates', payload => {
        // payload is a string in postgres.js, just like Mojo::Pg
        ctx.send({ json: JSON.parse(payload) });
    });

    // Clean up on WebSocket close
    ctx.on('close', () => {
        listener.unlisten();
    });
});

// 3. Helper to Broadcast Changes (Safe for Large Payloads)
app.decorateContext('notifyChange', async function(table, pk, type, data) {
    let payload = {
        table,
        pk,
        type,
        data
    };

    let jsonStr = JSON.stringify(payload);

    // Check byte length (Postgres NOTIFY limit is 8000 bytes)
    if (Buffer.byteLength(jsonStr) > 7500) {
        payload = {
            table,
            pk,
            type,
            truncated: true,
            data: { [pk]: data[pk] || pk } // Keep only the ID
        };
        jsonStr = JSON.stringify(payload);
    }

    await this.sql.notify('fireside_updates', jsonStr);
});

// 4. Generic REST API

// GET /DB/:table
app.get('/DB/:table', async ctx => {
    const table = ctx.req.params.table;
    // postgres.js uses tagged templates for safety against SQL injection
    // ctx.sql(table) treats the variable as an identifier (table name)
    const rows = await ctx.sql`SELECT * FROM ${ctx.sql(table)}`;
    await ctx.render({ json: rows });
});

// POST /DB/:table/:pk
app.post('/DB/:table/:pk', async ctx => {
    const { table, pk } = ctx.req.params;
    const json = await ctx.req.json();

    // Insert and return the Primary Key
    const [row] = await ctx.sql`
        INSERT INTO ${ctx.sql(table)} ${ctx.sql(json)}
        RETURNING ${ctx.sql(pk)}
    `;
    
    const id = row[pk];
    json[pk] = id;

    await ctx.notifyChange(table, id, 'INSERT', json);
    await ctx.render({ json: { pk: id } });
});

// PATCH /DB/:table/:pk/:id
app.patch('/DB/:table/:pk/:id', async ctx => {
    const { table, pk, id } = ctx.req.params;
    const json = await ctx.req.json();

    await ctx.sql`
        UPDATE ${ctx.sql(table)} 
        SET ${ctx.sql(json)} 
        WHERE ${ctx.sql(pk)} = ${id}
    `;

    await ctx.notifyChange(table, id, 'UPDATE', json);
    await ctx.render({ json: { status: 'ok' } });
});

// DELETE /DB/:table/:pk/:id
app.delete('/DB/:table/:pk/:id', async ctx => {
    const { table, pk, id } = ctx.req.params;

    await ctx.sql`
        DELETE FROM ${ctx.sql(table)} 
        WHERE ${ctx.sql(pk)} = ${id}
    `;

    await ctx.notifyChange(table, id, 'DELETE', {});
    await ctx.render({ json: { status: 'ok' } });
});

app.start();
```

A comprehensive, real-world use case utilizing these technologies can be found here:
<https://github.com/daboe01/Clinical>

## License
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/daboe01/cappusance?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
