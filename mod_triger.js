(function() {
    //    "use strict";
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
        parent: null,
        
        Agents: new Array(),
        Children: new Array(),
        
        MsgCenter: {
            Received: {},
            Sent: {}
        },

        known: {
            name: {
                msg: 'mod_triger message',
                ticket: 'mod_triger ticket',
                agent: 'mod_triger agent',
                event: 'mod_triger_msg_urgent',
                msg_transfer_station: 'Message Transfer Station'
            },
            uuid: {
                mod_id: 'ce9e3143-abee-4356-b1a1-2e0f27d037a7',
                search_key: '73b60b75-380d-47d9-809d-908736450d86',
                ticket_id: '18d29b50-0a92-46a0-a2ca-fbc8fd036c00',
                msg_id: '5ef66e29-374e-4481-9a87-b42548e072c9',
                agent_id: '37937b4c-ac16-4ac1-ae9b-2f44279c5646',
                main_js_file_id: 'd1dd4608-9b65-4437-b9b1-0a67efe892d1',
                our_js_dir: '5a4863c7-ca1a-41a2-8737-c502da05a8c3',
                msg_transfer_station: '8366e0c0-1e65-4aa5-8420-2ffa09081f67'
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
            version: '0.02',
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
            this.tkt_need_do = {};
            this.tkt_has_done = {};
            this.name = window.name;
            this.current_tkt = null;
            this.origin = null;
            
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
                var tkt_id;
                if (Array.isArray(p)) {
                    for (var i = 0; i < p.length;i++) {
                        tkt_id = p[i].id;
                        this.tkt_need_to_do[tkt_id] = p[i];
                    }
                } else
                if (ticket.is_tkt(p)) {
                    this.tkt_need_to_do[p.id] = p;
                }
                else {
                    throw p + ': is not a ticket or a ticket array';
                }
            }
            
            if (i > 5) {
                var p = arguments[5];
                var tkt_id;
                if (Array.isArray(p)) {
                    for (var i = 0; i < p.length;i++) {
                        tkt_id = p[i].id;
                        this.tkt_has_done[tkt_id] = p[i];
                    }
                } else
                if (ticket.is_tkt(p)) {
                    this.tkt_has_done[p.id] = p;
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
            
            get_agents_who_has_not_tkt_has_done: function() {
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

        /*
         * when_receive: function(msg_received, win_send_this_msg, origin_to_send) 
         * to_send(msg, win, origin)
         */
        message: {
            types: {
                ack: {
                    to_create: function() {
                        var msg_received, id_of_msg_received, msg;
                        
                        if (arguments.length != 1)
                            throw 'Need one argument';

                        msg_received = arguments[0];
                        
                        if (!mod_triger.message.is_msg(msg_received))
                            throw 'No message found';
                        
                        id_of_msg_received = msg_received.id;
                        
                        msg = new mod_triger.Message(
                            'ack',
                            {
                                reply_to: id_of_msg_received
                            }
                        );
                        
                        return msg;
                    },

                    when_receive: function() {
                        var msg_received, msg_id, msgs_sent;
                        var len = arguments.length;
                        
                        if (len < 1)
                            throw 'Need at least one argument';
                        
                        msg_received = arguments[0];
                        
                        if (!mod_triger.message.is_msg(msg_received))
                            throw 'Not a message found';

                        
                        msg_id = msg_received.data.reply_to;
                        msgs_sent = mod_triger.MsgCenter.Sent;
                        
                        if (msg_id in msgs_sent)
                            delete msgs_sent[msg_id];
                    },

                    to_send: function() {
                        
                        var msg_received, win, origin;
                        var len = arguments.length;

                        if (len < 2) {
                            if (window.opener)
                                throw 'Need at least one arguments';
                            else
                                throw 'Need at least two argument';
                        }

                        if (window.opener)
                            win = window.opener;
                        
                        if (len > 0) {
                            msg_received = arguments[0];
                            if (msg_received.type == 'ack')
                                return;
                        }
                        
                        if (len > 1)
                            win = arguments[1];

                        if (len > 2 )
                            origin = arguments[2];
                        else
                            origin = win.location.origin;

                        if (len > 3)
                            throw 'Too much arguments';
                        
                        var msg =
                                mod_triger.message.types.ack.to_create(msg_received);
                        
                        mod_triger.message.send_msg_to(msg, win, origin);
                    }
                },
                
                normal: {
                    to_create: function(data) {
                        var len = arguments.length;
                        var msg, type;
                        
                        type = 'normal';

                        if (len == 0)
                            data = {};
                        else if (len == 1) 
                            data = arguments[0];
                        else
                            throw 'Too many arguments';
                        
                        msg = new mod_triger.Message(
                            type,
                            { data: data }
                        );                        
                        
                        return msg;
                    },
                    
                    when_receive: function() {
                        var msg_received, win, origin;
                        
                        var len = arguments.length;
                        
                        var msg_id;

                        if (len < 2) {
                            if (window.opener)
                                throw 'Need at least one arguments';
                            else
                                throw 'Need at least two argument';
                        }

                        if (window.opener)
                            win = window.opener;
                        
                        if (len > 0)
                            msg_received = arguments[0];
                        
                        if (len > 1)
                            win = arguments[1];

                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;
                        
                        if (len > 3)
                            throw 'Too much arguments';

                        if (!mod_triger.message.is_msg(msg_received))
                            throw 'No message found';
                        
                        mod_triger.MsgCenter.Received[msg_received.id] = {
                            msg: msg_received,
                            win: win,
                            origin: origin
                        };
                        
                        mod_triger.message.types.ack.to_send(msg_received, win, origin);
                    },

                    to_send: function() {
                        var data, win, origin;
                        var msg;
                        
                        var len = arguments.length;
                        
                        if (len < 2) {
                            if (window.opener) {
                                if (len < 1)
                                    throw 'Need at least one arguments';
                            }
                            else { 
                                throw 'Need at least two arguments';
                            }
                        }

                        if (window.opener)
                            win = window.opener;
                        
                        if (len > 0)
                            data = arguments[0];

                        if (len > 1)
                            win = arguments[1];

                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;

                        if (len > 3)
                            throw 'Too much arguments';
                        
                        msg = mod_triger.message.types.normal.to_create(data);
                        mod_triger.message.send_msg_to(msg, win, origin);
                        mod_triger.MsgCenter.Sent[msg.id] = {
                            msg: msg,
                            win: win,
                            origin: origin
                        };
                    }
                },

                urgent: {
                    to_fire: function() {
                        var msg_received, win, origin;
                        var event;
                        
                        var len = arguments.length;

                        if (len < 2) {
                            if (window.opener)
                                throw 'Need at least one arguments';
                            else
                                throw 'Need at least two argument';
                        }

                        if (len > 0)
                            msg_received = arguments[0];

                        if (len > 1)
                            win = arguments[1];

                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;

                        event = new CustomEvent(mod_triger.known.name.event,
                                                {'detail': {
                                                    msg: msg_received,
                                                    win: win,
                                                    origin: origin
                                                }});

                        window.dispatchEvent(event);
                    },
                    
                    to_create: function(data) {
                        var len = arguments.length;
                        var msg, type;
                        
                        type = 'urgent';

                        if (len == 0)
                            data = {};
                        else if (len == 1) 
                            data = arguments[0];
                        else
                            throw 'Too many arguments';
                        
                        msg = new mod_triger.Message(
                            type,
                            { data: data }
                        );                        
                        
                        return msg;
                    },
                    
                    when_receive: function() {
                        var msg_received, win, origin;
                        
                        var len = arguments.length;
                        
                        var msg_id;

                        if (len < 2) {
                            if (window.opener)
                                throw 'Need at least one arguments';
                            else
                                throw 'Need at least two argument';
                        }

                        if (window.opener)
                            win = window.opener;
                        
                        if (len > 0)
                            msg_received = arguments[0];
                        
                        if (len > 1)
                            win = arguments[1];

                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;
                        
                        if (len > 3)
                            throw 'Too much arguments';

                        if (!mod_triger.message.is_msg(msg_received))
                            throw 'No message found';
                        
                        mod_triger.message.types.urgent.to_fire(msg_received, win, origin);
                        
                        mod_triger.message.types.ack.to_send(msg_received, win, origin);
                    },

                    to_send: function() {
                        var data, win, origin;
                        var msg;
                        
                        var len = arguments.length;
                        
                        if (len < 2) {
                            if (window.opener) {
                                if (len < 1)
                                    throw 'Need at least one arguments';
                            }
                            else { 
                                throw 'Need at least two arguments';
                            }
                        }

                        if (window.opener)
                            win = window.opener;
                        
                        if (len > 0)
                            data = arguments[0];

                        if (len > 1)
                            win = arguments[1];

                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;

                        if (len > 3)
                            throw 'Too much arguments';
                        
                        msg = mod_triger.message.types.urgent.to_create(data);
                        mod_triger.message.send_msg_to(msg, win, origin);
                        mod_triger.MsgCenter.Sent[msg.id] = {
                            msg: msg,
                            win: win,
                            origin: origin
                        };
                    }
                },
                
                ping: {
                    to_create: function() {
                        var msg;
                        var type = 'ping';
                        
                        if (arguments.length == 0) {

                            msg = new mod_triger.Message(
                                type,
                                {
                                    reply_to: '',
                                    status: false
                                }
                            );
                        }
                        else if (arguments.length == 1) {
                            var id_of_msg_received, msg
                            var msg_received = arguments[0];
                            
                            if (mod_triger.message.is_msg(msg_received)) {
                                id_of_msg_received = msg_received.id;
                                msg = new mod_triger.Message(
                                    type,
                                    {
                                        reply_to: id_of_msg_received,
                                        status: false
                                    }
                                );
                            }
                            else
                                msg = new mod_triger.Message(
                                    type,
                                    {
                                        reply_to: '',
                                        status: false
                                    }
                                ); 
                        }
                        else
                            throw 'Too many arguments';
                        
                        return msg;
                    },    

                    when_receive: function() {
                        var reply;
                        var msg_received, win, origin;
                        
                        var len = arguments.length;
                        
                        if (len < 2) {
                            if (window.opener) {
                                if (len < 1)
                                    throw 'Need at least one arguments';
                            }
                            else {
                                throw 'Need at least two arguments';
                            }
                        }
                        
                        if (window.opener)
                            win = window.opener;
                        
                        if (len > 0)
                            msg_received = arguments[0];
                        
                        if (len > 1)
                            win = arguments[1];
                        
                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;
                        
                        if (len > 3)
                            throw 'Too much arguments';

                        if (mod_triger.message.is_msg(msg_received))
                            reply = msg_received.data.reply_to;
                        else
                            throw 'No message found';
                        
                        if (reply == '')
                            mod_triger.message.types.ping.to_send(msg_received, win, origin);
                        else if (reply in mod_triger.MsgCenter.Sent) {
                            mod_triger.MsgCenter.Sent[reply].msg.data.status = true;
                            mod_triger.MsgCenter.Sent[reply].msg.data.replied_by = {
                                msg: msg_received,
                                source: win
                            };
                        }
                    },

                    to_send: function() {
                        var msg_received, win, origin;

                        var len = arguments.length;

                        if (len < 2) {
                            if (window.opener) {
                                if (len < 1)
                                    throw 'Need at least one arguments';
                            }
                            else {
                                throw 'Need at least two arguments';
                            }
                        }
                        
                        if (window.opener)
                            win = window.opener;

                        if (len > 0)
                            msg_received = arguments[0];
                        
                        if (len > 1)
                            win = arguments[1];
                        
                        if (len > 2)
                            origin = arguments[2];
                        else
                            origin = win.location.origin;
                        
                        if (len > 3)
                            throw 'Too much arguments';

                        if (mod_triger.message.is_msg(msg_received)) {
                            msg = mod_triger.message.types.ping.to_create(msg_received);
                        }
                        else {
                            msg = mod_triger.message.types.ping.to_create();
                            mod_triger.MsgCenter.Sent[msg.id] = {
                                msg: msg,
                                win: win,
                                origin: origin
                            };
                        }
                        
                        mod_triger.message.send_msg_to(msg, win, origin);
                    }
                }
            },
            
            is_msg: function(msg) {
                if (! msg)
                    return false;
                
                if (!('type'in msg
                      && 'wrapper' in msg
                      && 'name' in msg.wrapper
                      && 'id' in msg.wrapper))
                    return false;
                
                if (msg.wrapper.name == mod_triger.known.name.msg
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
                var msg, win, origin;

                var len = arguments.length;

                if (len < 1) {
                    if (!window.opener)                        
                        throw 'Need at least two arguments';
                    
                }
                
                if (len == 0)
                    msg = new mod_triger.Message();

                if (len > 0) {
                    msg = arguments[0];
                    if (! mod_triger.message.is_msg(msg))
                        throw msg + ' is not a message';
                }

                if (len > 1) {
                    win = arguments[1];
                }

                if (len > 2)
                    origin = arguments[2];
                else
                    origin = win.location.origin;

                
                if (len > 3)
                    throw 'To much arguments';
                
                win.postMessage(JSON.stringify(msg), origin);
            },

            send_msg_to_agent: function() {
                mod_triger.message.send_msg_to(msg, agent.win, agent.origin);
            },

            handler: function(e) {
                var msg, type;

                try {
                    msg = JSON.parse(e.data);
                    
                    if (! mod_triger.message.is_msg(msg))
                        return;

                    type = msg.type;

                    mod_triger.message.types[type].when_receive(msg, e.source, e.origin);
                }
                catch(e) {
                    ;
                }
                finally {
                    ;
                }
            }
            
        },

        /*
         * new Ticket()
         * new Ticket(action)
         * new Ticket(action, obj)
         * new Ticket(action, obj, target_path)
         */
        Ticket: function() {
            var len = arguments.length;

            this.is_ctrl = false;
            
            if (len == 0) {
                this.action = 'insert_js_file';
                this.store = {
                    path: mod_triger
                        .get_default_main_js_file_path()
                };
            }
            
            else if (len == 1) {
                this.action = arguments[0];
                this.store = {};
            }
            
            else if (len == 2) {
                this.action = arguments[0];
                this.store = arguments[1];
            }
            
            else if (len == 3) {
                this.action = arguments[0];
                this.store = arguments[1];
                this.target_path = arguments[2];
            }
            
            else if (len == 4) {
                this.action = arguments[0];
                this.store = arguments[1];
                this.target_path = arguments[2];
                this.is_ctrl = arguments[3];
            }
            
            if (! this.action in mod_triger.ticket.actions)
                throw this.action + ': unknown aciton found'

            var dt = new Date();
            this.tm_utc = dt.toUTCString();
            this.tm_local = dt.toString();
            this.status = mod_triger.ticket.status.queuing.to_create();
            this.id = mod_triger.uuidgen();
            
            this.wrapper = {
                id: mod_triger.known.uuid.ticket_id,
                name: mod_triger.known.name.ticket
            }
        },
        
        ticket: {
            actions: {
                set_agent_id: {
                    to_create: function() {
                        var uuid = mod_triger.uuidgen();
                        
                        var action = 'set_agent_id';

                        if (arguments.length > 0)
                            uuid = arguments[0];
                            
                        return new mod_triger.Ticket(
                            action,
                            {
                                uuid: uuid
                            }
                        );
                    },
                    
                    to_cash: function(tkt) {
                        if (!mod_triger.ticket.is_tkt(tkt))
                            throw 'The argument should be a ticket';
                        
                        var tkt_to_reply, agent_status, old_curr_tkt_status;
                        var old_curr_tkt = null;
                        var action = 'set_agent_id';

                        if (mod_triger.self && mod_triger.self.status)
                            agent_status = mod_triger.self.status;
                        else
                            agent_status = window.document.readyState;

                        if (mod_triger.self.current_tkt) {
                            old_curr_tkt = mod_triger.self.current_tkt;
                            old_curr_tkt_status = old_curr_tkt.status;
                            if (!(
                                old_curr_tkt_status == mod_triger
                                    .ticket
                                    .status.done
                                    .to_create()
                                    ||
                                    old_curr_tkt_status == mod_triger
                                    .ticket
                                    .status
                                    .now_no_tkt
                                    .to_create()
                            )) {
                                tkt_to_reply = mod_triger.ticket.actions
                                    .reply.to_create(tkt, {
                                        agent_status: agent_status,
                                        ticket_status: old_curr_tkt_status
                                    });
                                return tkt_to_reply;
                            }
                        }
                        else {
                            old_curr_tkt_status = mod_triger
                                .ticket.status
                                .now_no_tkt
                                .to_create();
                        }

                        if (tkt.action != action) {
                            tkt.status = mod_triger.ticket.status.failed.to_create();
                            throw 'Found a tiket that requires "'
                                + tkt.action
                                + ', while we need a '
                                + action
                                + ' one';
                        }


                        var uuid = tkt.store.uuid;
                        var tkt_id = tkt.id;
                        
                        mod_triger.self.current_tkt = tkt;
                        tkt.status = mod_triger.ticket.status.assigned.to_create();

                        if (!mod_triger.self)
                            throw 'The current agent is not exists';

                        mod_triger.self.id = uuid;
                        localStorage.setItem('AgentID', uuid);
                        tkt.status = mod_triger.ticket.status.done.to_create();
                        
                        return mod_triger
                            .ticket
                            .actions
                            .reply
                            .to_create(tkt,
                                       mod_triger
                                       .ticket
                                       .status
                                       .done
                                       .to_create()
                                      );
                    }
                },
                
                insert_js_file: {
                    // to_create(path) or to_create()
                    to_create: function() {                        
                        var path = mod_triger.get_default_main_js_file_path();
                        
                        if (arguments.length > 0)
                            path = arguments[0];
                        
                        var action = 'insert_js_file';
                        
                        return new mod_triger.Ticket(
                            action,
                            {
                                path: path
                            }
                        );
                    },

                    to_cash: function(tkt) {
                        if (!mod_triger.ticket.is_tkt(tkt))
                            throw 'The argument should be a ticket';
                        
                        var tkt_to_reply, agent_status, old_curr_tkt_status;
                        var old_curr_tkt = null;
                        var action = 'insert_js_file';

                        if (mod_triger.self && mod_triger.self.status)
                            agent_status = mod_triger.self.status;
                        else
                            agent_status = window.document.readyState;
                        
                        if (mod_triger.self.current_tkt) {
                            old_curr_tkt = mod_triger.self.current_tkt;
                            old_curr_tkt_status = old_curr_tkt.status;
                            if (!(
                                old_curr_tkt_status == mod_triger
                                    .ticket
                                    .status.done
                                    .to_create()
                                    ||
                                    old_curr_tkt_status == mod_triger
                                    .ticket
                                    .status
                                    .now_no_tkt
                                    .to_create()
                            )) {
                                tkt_to_reply = mod_triger.ticket.actions
                                    .reply.to_create(tkt, {
                                        agent_status: agent_status,
                                        ticket_status: old_curr_tkt_status
                                    });
                                return tkt_to_reply;
                            }
                        }
                        else {
                            old_curr_tkt_status = mod_triger
                                .ticket.status
                                .now_no_tkt
                                .to_create();
                        }

                        if (tkt.action != action) {
                            tkt.status = mod_triger.ticket.status.failed.to_create();
                            throw 'Found a tiket that requires "'
                                + tkt.action
                                + ', while we need a '
                                + action
                                + ' one';
                        }

                        
                        mod_triger.self.current_tkt = tkt;
                        tkt.status = mod_triger.ticket.status.assigned.to_create();
                        
                        var path = tkt.store.path;
                        var tkt_id = tkt.id;
                        
                        if ('js_inserted' in mod_triger.self && mod_triger.self.js_insered) {
                            if (path in mod_triger.self.js_insered) {
                                return mod_triger
                                    .ticket
                                    .actions
                                    .reply
                                    .to_create(tkt,
                                               mod_triger
                                               .ticket
                                               .status
                                               .done
                                               .to_create()
                                              );
                            }
                        } else {
                            mod_triger.self.js_insered = {};
                        }

                        var script_tag_id = mod_triger.uuidgen();
                        
                        mod_triger.self.js_insered[path] = script_tag_id;
                        
                        tkt.status = mod_triger.ticket.status.progressing.to_create();
                        
                        var script_tag = document.createElement("script");
                        script_tag.src = path;
                        script_tag.type = 'text/javascript';
                        script_tag.id = script_tag_id;
                        document.body.appendChild(script_tag);
                        
                        tkt.status = mod_triger.ticket.status.done.to_create();

                        return mod_triger
                            .ticket
                            .actions
                            .reply
                            .to_create(tkt,
                                       mod_triger
                                       .ticket
                                       .status
                                       .done
                                       .to_create()
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
                    },

                    to_cash: function(tkt) {
                        if (!mod_triger.ticket.is_tkt(tkt))
                            throw 'The argument should be a ticket';

                        var tkt_to_reply, agent_status, old_curr_tkt_status;
                        var old_curr_tkt = null;
                        var action = 'your_status';

                        if (mod_triger.self && mod_triger.self.status)
                            agent_status = mod_triger.self.status;
                        else
                            agent_status = window.document.readyState;
                        
                        if (mod_triger.self &&  mod_triger.self.current_tkt)
                            old_curr_tkt = mod_triger.self.current_tkt;

                        mod_triger.self.current_tkt = tkt;
                        tkt.status = mod_triger.ticket.status.assigned.to_create();

                        if (tkt.action != action) {
                            if (old_curr_tkt)
                                mod_triger.self.current_tkt = old_curr_tkt;
                            
                            return mod_triger
                                .ticket
                                .actions
                                .reply
                                .to_create(tkt,
                                           mod_triger
                                           .ticket
                                           .status
                                           .unknown_ticket
                                           .to_create()
                                          );
                        }
                        
                        if (old_curr_tkt)
                            old_curr_tkt_status = old_curr_tkt.status;
                        else
                            old_curr_tkt_status = mod_triger
                            .ticket.status
                            .now_no_tkt
                            .to_create();

                        tkt_reply = mod_triger.ticket.actions.reply.to_create(tkt, {
                            agent_status: agent_status,
                            ticket_status: old_curr_tkt_status
                        });

                        mod_triger.self.current_tkt.status =
                            mod_triger.ticket.status.done.to_create();
                        
                        if (old_curr_tkt)
                            mod_triger.current_ticket = old_curr_tkt;
                        
                        return tkt_reply;
                    }
                },
                
                close: {
                    to_create: function() {
                        var action = 'close';
                        
                        return new mod_triger.Ticket(
                            action,
                            {}
                        );
                    },
                    
                    to_cash: function(tkt) {
                        if (!mod_triger.ticket.is_tkt(tkt))
                            throw 'The argument should be a ticket';

                        if (tkt.status != mod_triger
                            .ticket
                            .status
                            .queuing
                            .to_create()) {
                            return mod_triger
                                .ticket
                                .actions
                                .reply
                                .to_create(tkt, {
                                    this_ticket_status: tkt.status
                                });
                        }
                        
                        var tkt_to_reply, agent_status;
                        var old_curr_tkt_status;
                        var old_curr_tkt = null;
                        var action = 'close';

                        if (mod_triger.self && mod_triger.self.status)
                            agent_status = mod_triger.self.status;
                        else
                            agent_status = window.document.readyState;
                        
                        if (mod_triger.self && mod_triger.self.current_tkt)
                            old_curr_tkt = mod_triger.self.current_tkt;

                        
                        
                        mod_triger.self.current_tkt = tkt;
                        
                        tkt.status = mod_triger.ticket
                            .status
                            .assigned
                            .to_create();

                        if (old_curr_tkt) {
                            if (
                                old_curr_tkt_status == mod_triger
                                    .ticket
                                    .status.done
                                    .to_create()
                                    ||
                                    old_curr_tkt_status == mod_triger
                                    .ticket
                                    .status
                                    .now_no_tkt
                                    .to_create()
                            ) {
                                old_curr_tkt_status =
                                    old_curr_tkt.status;                                
                            }
                            else {
                                tkt_to_reply = mod_triger.ticket.actions
                                    .reply.to_create(tkt, {
                                        agent_status: agent_status,
                                        ticket_status: old_curr_tkt_status,
                                    });
                                return tkt_to_reply;
                            }
                        }
                        else {
                            old_curr_tkt_status = mod_triger
                                .ticket
                                .status
                                .now_no_tkt
                                .to_create();
                        }
                        
                        tkt_to_reply = mod_triger.ticket.actions
                            .reply.to_create(tkt,
                                             mod_triger
                                             .ticket
                                             .status
                                             .assigned
                                             .to_create()
                                            );

                        mod_triger.self.current_tkt = tkt;
                        tkt.status = mod_triger.ticket.status.assigned.to_create();

                        setTimeout(function() { window.close() }, 5000);
                        setTimeout(function() { window.close() }, 10000);
                        
                        tkt.status = mod_triger.ticket.status.done.to_create();
                        
                        return tkt_to_reply;
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
                    },

                    to_cash: function(tkt) {
                        true;
                    }
                }
            },

            status: {
                // ticket doing status
                queuing: {
                    to_create: function() {
                        return 'queuing';
                    }
                },
                
                assigned: {
                    to_create: function() {
                        return 'assigned';
                    }
                },
                
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
                
                unknown_ticket:  {
                    to_create: function() {
                        return 'unknown_ticket';
                    }
                },

                now_no_tkt: {
                    to_create: function() {
                        return 'now_no_tkt';
                    }
                }
            },
            
            send_to_agent: function(ticket, agent, origin) {
                mod_triger.message.types.normal.to_send(ticket, agent.win, agent.origin);
            },
            
            send_to_win: function(ticket, win, origin) {
                mod_triger.message.types.normal.to_send(ticket, win, origin);
            },

            send_to_agent_as_urgent: function(ticket, agent, origin) {
                mod_triger.message.types.urgent.to_send(ticket, agent.win, agent.origin);
            },
            
            send_to_win_as_urgent: function(ticket, win, origin) {
                mod_triger.message.types.urgent.to_send(ticket, win, origin);
            },
            
            get_from_msg_stored: function(msg_stored) {
                return msg_stored.msg.data.data;
            },
            
            get_from_localstorage: function() {
                var str_ticket = localStorage.getItem(mod_triger
                                                      .known.uuid
                                                      .ticket_id);
                if (str_ticket)
                    return JSON.parse(str_ticket);
                else
                    return null;
            },

            get_from_sessionstorage: function() {
                var str_ticket = sessionStorage.getItem(mod_triger.known.uuid
                                                        .ticket_id);
                if (str_ticket)
                    return JSON.parse(str_ticket);
                else
                    return null;
            },
            
            is_tkt: function(tkt) {
                return true;
            }
        },
        
        get_default_main_js_file_path: function() {
            var dir = mod_triger.get_default_js_file_dir();

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

        mark_localstorage_parameters: function() {
            if (window.location.protocol == "file:") {
                localStorage.setItem(mod_triger.known.uuid.search_key,
                                     window.location.pathname);
            }
            else
                localStorage.setItem(mod_triger.known.uuid.search_key,
                                     window.location.origin);
        },
        
        declare_self_is_complete: function() {
            var w = window.opener;
            if (w)
                w.postMessage('complete', w.location.origin);
            else
                mod_triger.self.status = 'complete';
        },

        
        get_default_js_file_dir: function() {
            if (location.protocol == 'file:') {
                return '';
            }
            else {
                var dir = location.origin.replace(/\//g, '')
                        .replace(':', '.');
                
                return '/'
                    + mod_triger.known.uuid.our_js_dir
                    +'/'
                    + dir
                    + '/';
            }
        },

        // You can give each origin a control ticket if need.
        main: function() {
            if (!(mod_triger.known.uuid.search_key in localStorage)) {
                mod_triger.mark_localstorage_parameters();
                window.close();
            }

            window.addEventListener('message',
                                    mod_triger
                                    .message
                                    .handler,
                                    false);
            
            if (mod_triger.self === null) {
                mod_triger.self = new mod_triger.Agent(window
                                                       .location
                                                       .pathname,
                                                       window);
                if (localStorage.getItem('AgentID')) {
                    mod_triger.self.id = localStorage.getItem('AgentID');
                }
                mod_triger.Agents.push(self);
            }
            
            document.onreadystatechange = function () {
                mod_triger.self.status = window.document.readyState;
                mod_triger.self.origin = window.location.origin;
            };

            var ticket_rep;
            var ticket = mod_triger.ticket.get_from_localstorage();
            var ticket_in_sessionstorage =
                    mod_triger
                    .ticket
                    .get_from_sessionstorage();
            
            // If the agent is control agent
            if (ticket
                && ticket.status == mod_triger.ticket.status.queuing.to_create()
                && ticket.is_ctrl == "true"
                && !ticket_in_sessionstorage) { 

                if ('target_path' in ticket 
                    && ticket.target_path != location.pathname) {
                    window.location = target_path;
                    return;
                }

                mod_triger.self.is_control_agent = true;
                
                ticket.status = mod_triger.ticket.status.assigned.to_create();
                
                localStorage.setItem(mod_triger.known.uuid.ticket_id,
                                     JSON.stringify(ticket));
                sessionStorage.setItem(mod_triger.known.uuid.ticket_id,
                                       JSON.stringify(ticket));
                
                mod_triger.self.tkt_need_do[ticket.id] = ticket;

                ticket_rep = mod_triger.ticket.actions.insert_js_file.to_cash(ticket);
                mod_triger.self.tkt_has_done[ticket.id] = ticket;

                delete mod_triger.self.tkt_need_do[ticket.id];
            }
            
            // If the agent is normal            
            if (ticket
                && ticket.status == mod_triger.ticket.status.queuing.to_create()
                && ! (ticket.is_ctrl)) {
                if (mod_triger.self.id == mod_triger.known.uuid.msg_transfer_station) {
                    mod_triger.self.name = mod_triger.known.name.msg_transfer_station;
                }
                else {
                    mod_triger.self.is_control_agent = true;
                    console.log('Normal agent')
                }
            }
        },

    };
    
    mod_triger.main();
    
})();
