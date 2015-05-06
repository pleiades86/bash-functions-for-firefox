(function() {
    if ('mod_triger' in window) {
        var errorMsg = 'The name mod_triger has been used'; 
        if ('mod_info' in mod_triger
            && 'id' in mod_triger.mod_info
            && mod_triger.mod_info.id
            == 'ce9e3143-abee-4356-b1a1-2e0f27d037a7') {
            delete window.mod_triger;
        }
        else {
            throw errorMsg;
        }
    }
    
    mod_triger = {
        self: null,        
        Agents: new Array(),
        Messages: {
            Received: {},
            Sent: {}
        },

        known: {
            name: {
                msg: 'mod_triger message',
                ticket: 'mod_triger ticket',
                agent: 'mod_triger agent'
            },
            uuid: {
                mod_id: 'ce9e3143-abee-4356-b1a1-2e0f27d037a7',
                search_key: '73b60b75-380d-47d9-809d-908736450d86',
                ticket_id: '18d29b50-0a92-46a0-a2ca-fbc8fd036c00',
                msg_id: '5ef66e29-374e-4481-9a87-b42548e072c9',
                agent_id: '37937b4c-ac16-4ac1-ae9b-2f44279c5646',
                main_js_file_id: 'd1dd4608-9b65-4437-b9b1-0a67efe892d1',
                our_js_dir: '5a4863c7-ca1a-41a2-8737-c502da05a8c3'
            }
        },
        

        uuidgen: function() {
            var d = new Date().getTime();
            var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
                    .replace(/[xy]/g, function(c) {
                        var r = (d + Math.random()*16)%16 | 0;
                        d = Math.floor(d/16);
                        return (c=='x' ? r : (r&0x3|0x8)).toString(16);
                    });
            return uuid;
        },

        mod_info: {
            id: 'ce9e3143-abee-4356-b1a1-2e0f27d037a7',
            version: '0.01',
            author: 'xning',
            email: 'anzhou94@gmail.com',
            descr: 'JavaScript functions, which wrappered HTML5 APIs, '
                + 'to work with Apache HTTPD mod_triger module together'
        },

        introduce_youself: function() {
            for (var k in mod_triger.mod_info) {
                console.log(k + ': ' + mod_triger.mod_info[k]);
            }
        },
        
        /*
         *  Agent(path)
         *  Agent(path, win)
         *  Agent(path, win, status)
         *  Agent(path, win, status, is_control_agent)
         *  Agent(path, win, status, is_control_agent, tkt_need_to_do)
         */
        Agent: function() {
            
            this.path = null;
            this.win = null;
            this.status = 'inactive';
            this.is_control_agent = false;
            this.tkt_need_do = new Array();
            this.tkt_has_done = new Array();

            var i = arguments.length;
            
            if (i > 0) {
                this.path = arguments[0];
            }
            
            if (i > 1) {
                this.win = arguments[1];
            }
            
            if (i > 2) {
                status_str = arguments[2];
                if (status_str in mod_triger.agent.status)
                    this.status = status_str;
                else
                    throw status_str + ': unknown agent status type';
            }
            
            if (i > 3) {
                var p = arguments[3];
                if (typeof(p) == typeof(true)) {
                    this.is_control_agent = p;
                } else
                throw p + ': is not a boolean value';
            }
            
            if (i > 4) {
                var p = arguments[4];
                if (Array.isArray(p)) {
                    for (var i = 0; i < p.length;i++) {
                        this.tkt_need_to_do.push(p[i]);
                    }
                } else
                if (ticket.is_tkt(p)) {
                    this.tkt_need_to_do.push(p);
                }
                else {
                    throw p + ': is not a ticket or a ticket array';
                }
            }
            
            if (i > 5) {
                var p = arguments[5];
                if (Array.isArray(p)) {
                    for (var i = 0; i < p.length;i++) {
                        this.tkt_has_done.push(p[i]);
                    }
                } else
                if (ticket.is_tkt(p)) {
                    this.tkt_has_done.push(p);
                }
                else {
                    throw p + ': is not a ticket or a ticket array';
                }
            }
            
            if (i > 6) {
                throw 'It is too much arguments to create an Agent';
            }

            this.id = mod_triger.uuidgen();
            
            this.wrapper = {
                name: mod_triger.known.name.agent,
                id: mod_triger.known.uuid.agent_id
            };
        },

        agent: {
            status: {
                //agent status
                loading: {
                    to_create: function() {
                        return 'loading';
                    }
                },
                
                inactive: {
                    to_create: function() {
                        return 'inactive'
                    }
                },

                active: {
                    to_create: function() {
                        return 'inactive'
                    }
                },
                
                loading: {
                    to_create: function() {
                        return 'loading';
                    }
                },

                interactive: {
                    to_create: function() {
                        return 'interactive';
                    }
                },
                
                complete: {
                    to_create: function() {
                        return 'complete';
                    }
                },

                closed:  {
                    to_create: function() {
                        return 'closed';
                    }
                },
                
                no_response: {
                    to_create: function() {
                        return 'no_response';
                    }
                },
                
                // ticket doing status
                progressing:  {
                    to_create: function() {
                        return 'progressing';
                    }
                },
                done: {
                    to_create: function() {
                        return 'done';
                    }
                },
                busy: {
                    to_create: function() {
                        return 'busy';
                    }
                },
                failed:  {
                    to_create: function() {
                        return 'failed';
                    }
                },
                
                unknown_status:  {
                    to_create: function() {
                        return 'unkown_status';
                    }
                }
            },

            probe_win_status: function(win) {
                if (win.closed)
                    return mod_triger.agent.status.closed.to_create();
                
                return mod_triger.agent.status[win.document.readyState].to_create();
            },
            
            probe_agent_status: function(agent) {                
                return mod_triger.agent.probe_win_status(agent.win);
            },

            
            is_the_agent_ready_whose_win_is: function(win) {
                var Agents = mod_triger.Agents;

                for (var i = 0;i < Agents.length;i++) {
                    if (Agents[i].win === win) {
                        if (Agents[i].status == 'active') 
                            return true;
                    }
                }
                
                return false;
            },

            
            get_agent_by_win: function(win) {
                var agent = null;
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    if (Agents[i].win === win) {
                        agent = Agents[i];
                        break;
                    }
                }

                if (agent === null)
                    throw 'No agent owns the window ' + win.location.href
                    +' fonund';
                
                return agent;
            },

            
            get_agent_by_msg: function(msg) {
                var agent = null;
                var win = msg.source;
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    if (Agents[i].win === win) {
                        agent = Agents[i];
                        break;
                    }
                }
                
                if (agent === null) {
                    throw 'No agent for the message ' + msg.data.id
                        + ' fonund, The message comes from '
                        + win.location.href ;
                }
                
                return agent;
            },

            get_agent_by_its_id: function(uuid) {
                var agent = null;
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    if (Agents[i].id == uuid) {
                        agent = Agents[i];
                        break;
                    }
                }

                if (agent === null) {
                    throw 'No agent has the id ' + uuid;
                }
                
                return agent;
            },

            get_agents_who_has_tkt_need_do: function() {
                var agents = new Array();
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    var agent = Agents[i];
                    if (Object.keys(agent.tkt_need_do).length != 0)
                        agents.push(agent);
                }
                
                return agents;
            },

            get_agents_who_has_not_tkt_need_do: function() {
                var agents = new Array();
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    var agent = Agents[i];
                    if (Object.keys(agent.tkt_need_do).length == 0)
                        agents.push(agent);
                }
                
                return agents;
            },

            get_agents_who_has_tkt_has_done: function() {
                var agents = new Array();
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    var agent = Agents[i];
                    if (Object.keys(agent.tkt_has_done).length != 0)
                        agents.push(agent);
                }
                
                return agents;
            },
            
            get_agents_who_has_tkt_has_done: function() {
                var agents = new Array();
                var Agents = mod_triger.Agents;
                
                for (var i = 0;i < Agents.length;i++) {
                    var agent = Agents[i];
                    if (Object.keys(agent.tkt_has_done).length == 0)
                        agents.push(agent);
                }
                
                return agents;
            }
        },

        
        /*
         *  Message()
         *  Message(type)
         *  Message(type, data)
         */
        Message: function() {

            this.type = 'ping';
            this.data = {};
            
            var i = arguments.length;
            
            if (i > 0) {
                var type =arguments[0];
                if (type in mod_triger.message.types)
                    this.type = type;
                else
                    throw type + ': unknown message type';
            }
            
            if (i >1)
                this.data = arguments[1];

            if (i >2)
                throw 'Too much arguments to create a message'
            
            this.id = mod_triger.uuidgen();
            this.wrapper = {
                id: mod_triger.known.uuid.msg_id,
                name: mod_triger.known.name.msg
            };
        },

        message: {
            types: {
                ack: {
                    to_create: function() {

                        var msg_to_reply = new Array();
                        var len = arguments.length;

                        if (len == 0)
                            throw 'The ' + type + ' message need at least an argument';

                        for (var i = 0;i < len; i++) {
                            var msg_received = arguments[i];
                            var id_of_msg_received = msg_received.data.id;
                            msg_to_reply.push(id_of_msg_received);
                        }
                        
                        var msg = new mod_triger.Message(
                            'ack',
                            {
                                reply_to_msg: msg_to_reply
                            }
                        );
                        
                        return msg;
                    },

                    when_receive: function(msg) {
                        var data = JSON.parse(msg.data);
                        var msgs_ids_be_replied = data.data.reply_to_msg;

                        var msgs_sent = mod_tirger.Messages.sent;

                        for (var i = 0;i < msgs_ids_be_replied.length;i++) {
                            var msg_id = msgs_ids_be_replied[i];
                            if (msg_id in msgs_sent)
                                delete msgs_sent[msg_id];
                        }                        
                    },

                    to_send: function(msg_received) {
                        var data = JSON.parse(msg_received.data);

                        if (data.type == 'ack')
                            return;
                        
                        var source = msg_received.source;
                        var reply_msg = mod_triger.message.types.ack.to_create(msg_received);
                        send_msg_to(reply_msg, win);
                    }
                },
                
                normal: {
                    to_create: function() {
                        var msg, type;
                        var msg_to_reply = new Array();
                        
                        type = 'normal';
                        
                        if (arguments.length == 0) {
                            throw 'Need at least an argument to create a' + type + ' message';
                        }
                        
                        if (arguments.length == 1) {
                            msg = new mod_triger.Message(
                                type,
                                { data: arguments[0] }
                            );
                        }
                        
                        if (arguments.length > 1) {
                            
                            for (var i = 1;i < len; i++) {
                                var msg_received = arguments[i];
                                var id_of_msg_received = msg_received.data.id;
                                msg_to_reply.push(id_of_msg_received);
                            }    
                            
                            msg = new mod_triger.Message(
                                type,
                                {
                                    reply_to_msg: msg_to_reply,
                                    data: arguments[0]
                                }
                            );
                        }
                        
                        return msg;
                    },
                    
                    when_receive: function(msg) {
                        var data = JSON.parse(msg.data);
                        var msg_id = data.id;
                        
                        mod_triger.Messages.Received[msg_id] = {
                            data: data,
                            source: msg.source
                        };
                        
                        mod_triger.message.types.ack.to_send(msg);
                    },

                    to_send: function() {
                        var data, win;
                        
                        if (window.opener)
                            win = window.opener;
                        if (arguments.length == 0)
                            throw 'Need an arugment';

                        if (arguments.length > 0)
                            data = arguments[0];

                        if (arguments.length > 1)
                            win = arguments[1];

                        if (arguments.length > 2)
                            throw 'Too many arguments';

                        var msg = mod_triger.message.types.normal.to_create(data);
                        send_msg_to(msg, win);
                    }
                },

                /*
                 * Don't implement the urgent type
                 */
                urgent: {
                    to_create: function(obj) {
                        var msg, type;
                        var msg_to_reply = new Array();
                        
                        var type = 'urgent';

                        if (arguments.length == 0) {
                            throw 'Need at least an argument to create a' + type + ' message';
                        }
                        
                        if (arguments.length == 1) {
                            msg = new mod_triger.Message(
                                type,
                                { data: arguments[0] }
                            );
                        }
                        
                        if (arguments.length > 1) {

                            for (var i = 1;i < len; i++) {
                                var msg_received = arguments[i];
                                var id_of_msg_received = msg_received.data.id;
                                msg_to_reply.push(id_of_msg_received);
                            }
                            
                            msg = new mod_triger.Message(
                                type,
                                {
                                    reply_to_msg: msg_to_reply,
                                    data: arguments[0]
                                }
                            );
                        }
                        
                        return msg;
                    }
                    
                },
                
                ping: {
                    to_create: function() {
                        var msg, type, id_of_msg_received;

                        var type = 'ping';
                        
                        if (arguments.length == 0) {
                            msg = new mod_triger.Message(
                                type,
                                {}
                            );
                        }
                        
                        if (arguments.length == 1) {
                            id_of_msg_received = arguments[0].data.id;
                            msg = new mod_triger.Message(
                                type,
                                { reply_to_msg: id_of_msg_received }
                            );
                        } else
                        if (arguments.length > 1) {
                            msg = new mod_triger.Message(
                                type,
                                {
                                    reply_to_msg: id_of_msg_received,
                                    data: arguments[1]
                                }
                            );
                        } else
                        if (arguments.length > 2) {
                            throw 'Too much arguments to create a' + type + ' message';
                        }
                        
                        return msg;
                    },    

                    when_receive: function(msg) {
                        var win = msg.source;
                        var data = JSON.parse(msg.data);
                        
                        if ('reply_to_msg' in data.data) {
                            var msgs_ids_be_replied = data.data.reply_to_msg;

                            var msgs_sent = mod_triger.Messages.Sent;
                            for (var i = 0;i < msgs_ids_be_replied.length;i++) {
                                var msg_id = msgs_ids_be_replied[i];
                                if (msg_id in msgs_sent)
                                    delete msgs_sent[msg_id];
                            }
                        }

                        var msg = mod_triger.message.types.ping.to_create();
                        mod_triger.message.send_msg_to(msg, win);
                        
                    },

                    to_send: function(win) {
                        var msg = mod_triger.message.types.ping.to_create();
                        mod_triger.message.send_msg_to(msg, win);
                    }
                }
            },
            
            is_msg: function(msg) {
                if (msg.name == mod_triger.known.name.msg
                    && msg.wrapper.id == mod_triger.known.uuid.msg_id
                    && (msg.type in mod_triger.message.types))
                    return true;
                return false;
            },
            
            is_msg_from_win: function(msg, win) {
                if (mod_triger.message.is_msg(msg))
                    if (msg.source === win)
                        return true;
                
                return false;
            },
            
            is_msg_from_agent: function(agent) {
                if (mod_triger.message.is_msg_from_win(agent.win))
                    return true;
                
                return false;
            },

            send_msg_to: function() {
                var msg, win;
                win = window.opener;
                
                if (arguments.length == 0)
                    throw 'Need at least an argument'

                if (arguments.length > 0) {
                    msg = arguments[0];
                    if (! mod_triger.message.is_msg(msg))
                        throw msg + ' is not a message';
                }

                if (arguments.length > 1) {
                    win = arguments[1];
                }

                if (arguments.length > 2)
                    throw 'Too much argumemnts';

                win.postMessage(JSON.stringify(msg), win.location.origin);
            },

            send_msg_to_agent: function(msg, agent) {
                mod_triger.message.send_msg_to(msg, agent.win);
            },

            handler: function(e) {
                if (e.origin != window.location.origin)
                    return;

                try {
                    var data = JSON.parse(e.data);
                    
                    if (! mod_triger.message.is_msg(data))
                        return;
                    
                    if (mod_triger.message.is_msg(data))
                        mod_triger.Messages.Received[data.id] = {
                            data: data,
                            source: e.source,
                            origin: e.origin
                        };
                }
                catch(e) {
                    ;
                }
                finally {
                    ;
                }
            }

            
        },

        Ticket: function(action, obj) {
            this.action = action;
            if (! action in ticket.actions)
                throw acion + ': unknown aciton found'

            this.store = obj;
            this.id = mod_triger.uuidgen();
            
            this.wrapper = {
                id: mod_triger.known.uuid.ticket_id,
                name: mod_triger.known.uuid.ticket
            }
        },

        ticket: {
            actions: {
                insert_js_file: {
                    to_create: function(path) {
                        var action = 'insert_js_file';
                        
                        return new mod_triger.Ticket(
                            action,
                            {
                                path: path
                            }
                        );
                    }
                },

                your_status: {
                    to_create: function() {
                        var action = 'your_status';
                        
                        return new mod_triger.Ticket(
                            action,
                            {}
                        );
                    }
                },
                
                close: {
                    to_create: function() {
                        var action = 'close';
                        
                        return new mod_triger.Ticket(
                            action,
                            {}
                        );
                    }
                },

                reply: {
                    to_create: function(req_tkt, result) {
                        var action = 'reply';
                        var req_tkt_id = req_tkt.id;
                        var data = {
                            reply_to_tkt: req_tkt_id,
                            data: result
                        }

                        return new mod_triger.Ticket(
                            action,
                            data
                        );
                    }
                }
            },

            get_from_localstorage: function() {
                var str_ticket = localStorage.getItem(mod_triger.known.uuid
                                                      .ticket_id);
                return JSON.parse(str_ticket);
            },
            
            do: function() {
                var ticket = mod_triger.ticket.get_from_localstorage();
                
                if ('target_path' in ticket 
                    && ticket.target_path != location.pathname) {
                    mod_triger.declare_self_is_complete();
                    return;
                }
                
                if (mod_triger.known.uuid.ticket_id in sessionStorage) {
                    var session_ticket_str =
                            sessionStorage.getItem(mod_triger.known.uuid
                                                   .ticket_id);
                    var session_ticket = JSON.parse(session_ticket_str);
                    if (session_ticket.status == 'assigned') {
                        mod_triger.declare_self_is_complete();
                        return;
                    }
                }
                
                ticket.status = "assigned";
                localStorage.setItem(mod_triger.known.uuid.ticket_id,
                                     JSON.stringify(ticket));
                sessionStorage.setItem(mod_triger.known.uuid.ticket_id,
                                       JSON.stringify(ticket));
                
                if ('path' in ticket) {
                    //mod_triger.insert_js_file(ticket.path);
                    mod_triger.self.js_file_path = ticket.path;
                }
                else {
                    var default_js_file_path = mod_triger
                            .get_default_main_js_file_path();
                    
                    mod_triger.insert_js_file(default_js_file_path);
                    mod_triger.self.js_file_path = default_js_file_path;
                }
                
                mod_triger.self.is_the_js_file_insert = true;
                mod_triger.self.is_control_agent = true;
                mod_triger.self.status = mod_triger.agent.status.active.to_create();
                mod_triger.declare_self_is_complete();
            },

            is_tkt: function(tkt) {
                return true;
            }
        },

        
        get_default_js_file_dir: function() {
            if (location.protocol == 'file:') {
                return '';
            }
            else {
                var dir = location.origin.replace(/\//g, '')
                        .replace(':', '.');
                
                return '/'
                    + mod_triger.konwn.uuid.our_js_dir
                    +'/'
                    + dir
                    + '/';
            }
        },

        get_default_main_js_file_path: function() {
            var dir = mod_triger.get_default_js_file_dir();
            console.log("dir " + dir);
            if (location.protocol == 'file:') {
                return dir + location.pathname + '.js';
            }
            else {
                return dir + 'main.js';
            }
        },
        
        insert_js_file: function(path) {
            var script_tag = document.createElement("script");
            script_tag.src = path;
            script_tag.type = 'text/javascript';
            document.body.appendChild(script_tag);
        },

        
        declare_self_is_complete: function() {
            var w = window.opener;
            if (w)
                w.postMessage('complete', w.location.origin);
            else
                mod_triger.self.status = 'complete';
        },

        mark_localstorage_parameters: function() {
            if (window.location.protocol == "file:") {
                localStorage.setItem(mod_triger.known.uuid.search_key,
                                     window.location.pathname);
            }
            else
                localStorage.setItem(mod_triger.known.uuid.search_key,
                                     window.location.origin);
        }
    };
    
    window.addEventListener('message',
                            mod_triger.message.handler,
                            false);

    if (!(mod_triger.known.uuid.search_key in localStorage)) {
        mod_triger.mark_localstorage_parameters();
        window.close();
    }
    
    if (mod_triger.known.uuid.ticket_id in localStorage) {
        if (mod_triger.self === null) {
            mod_triger.self = new mod_triger.Agent(window.location.pathname, window);
            mod_triger.Agents.push(self);
        }
        
        mod_triger.ticket.do();
    }
})();
