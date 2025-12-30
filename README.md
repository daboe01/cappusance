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

### 4. The Backend (Mojolicious)
**[Mojolicious](http://mojolicio.us/)** with `Mojo::Pg` is a perfect match as this framework easily provides the REST API and the WebSocket stream. The following generic script handles CRUD and broadcasts updates to all connected clients. You could use this script with minimal modifications for all your projects. However, because Fireside is backend-agnostic any other backend will do.

```perl
use Mojolicious::Lite;
use Mojo::Pg;
use Mojo::JSON qw(encode_json decode_json);

# 1. Connect to Postgres
helper pg => sub { state $pg = Mojo::Pg->new('postgresql://postgres@localhost/name_of_your_postgres_database') };

# 2. WebSocket Route for Live Sync
websocket '/DB/socket' => sub {
    my $c = shift;
    $c->inactivity_timeout(3600);

    # Listen for PG notifications and forward to WebSocket
    my $cb = $c->pg->pubsub->listen(fireside_updates => sub {
        my ($pubsub, $payload) = @_;
        $c->send({json => decode_json($payload)});
    });

    $c->on(finish => sub { shift->pg->pubsub->unlisten(fireside_updates => $cb) });
};

# 3. Helper to Broadcast Changes (Safe for Large Payloads)
helper notify_change => sub {
    my ($self, $table, $pk, $type, $data) = @_;

    my $payload = {
        table => $table,
        pk    => $pk,
        type  => $type,
        data  => $data
    };

    my $json_str = encode_json($payload);

    if (length($json_str) > 7500) {
        $payload = {
            table     => $table,
            pk        => $pk,
            type      => $type,
            truncated => Mojo::JSON->true,
            # IMPORTANT: We still send the PK inside 'data' so the
            # frontend cache logic works without modification.
            data      => { id => $pk }
        };

        $json_str = encode_json($payload);
    }

    $self->pg->pubsub->notify(fireside_updates => $json_str);
};

# 4. Generic REST API
get '/DB/:table' => sub {
    my $c = shift;
    $c->render(json => $c->pg->db->select($c->param('table'))->hashes);
};

post '/DB/:table/:pk' => sub {
    my $c = shift;
    my ($table, $pk) = ($c->param('table'), $c->param('pk'));
    my $json = $c->req->json;
    
    my $id = $c->pg->db->insert($table, $json, {returning => $pk})->hash->{$pk};
    $json->{$pk} = $id;
    
    $c->notify_change($table, $id, 'INSERT', $json);
    $c->render(json => {pk => $id});
};

patch '/DB/:table/:pk/:id' => sub {
    my $c = shift;
    my ($table, $pk, $id) = ($c->param('table'), $c->param('pk'), $c->param('id'));
    my $json = $c->req->json;

    $c->pg->db->update($table, $json, {$pk => $id});
    $c->notify_change($table, $id, 'UPDATE', $json);
    $c->render(json => {status => 'ok'});
};

del '/DB/:table/:pk/:id' => sub {
    my $c = shift;
    my ($table, $pk, $id) = ($c->param('table'), $c->param('pk'), $c->param('id'));
    
    $c->pg->db->delete($table, {$pk => $id});
    $c->notify_change($table, $id, 'DELETE', {});
    $c->render(json => {status => 'ok'});
};

app->start;
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
