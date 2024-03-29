// ==UserScript==
// @name          Fastmail Shortcuts
// @downloadURL   https://raw.githubusercontent.com/rjbs/misc/main/fastamper.js
// @namespace     https://rjbs.cloud/
// @homepage      https://github.com/rjbs/misc/blob/main/fastamper.js
// @version       0.103
// @description   mouse less, keyboard more
// @author        Ricardo Signes
// @match         https://*.fastmail.com/*
// @grant         none
// ==/UserScript==

(function() {
  'use strict';
  const observer = new MutationObserver(() => {
    // Here, we boot up only once the JMAP UI is actually loaded and has
    // eliminated the bootstrap content from the DOM.
    //
    // I think a problem here is that because we disconnect the observer, then
    // when the page reloads the application, the Tampermonkey code is not
    // re-applied.  I'm not sure if that's true.  To diagnose it, I think I'll
    // need to do shenanigans to trigger the reloading. -- rjbs, 2022-06-11
    if (document.getElementById('bootstrap-page')) {
      return;
    }
    observer.disconnect();

    // // //
    //
    // HELPER FUNCTIONS
    //
    // // //

    // getMail: get the active mail controller
    const getMail = () => FM.router.getAppController('mail');

    // getViewsByClass: find all the views of a given class in the app
    const getViewsByClass = (viewClass) => {
      return Object.values(FM.activeViews).filter(view => view instanceof viewClass);
    };

    // // //
    //
    // ALTERNATIVE BADGES
    //
    // We replace how the badges on some mailboxes are drawn.  Any mailbox
    // that's marked "hide if empty", we take to be a "workflow mailbox",
    // meaning that any mail at all in that mailbox is a todo item.  We'll use
    // the badge to indicate how many messages are there, not (as usual) how
    // many are unread.  We also add the rjbs-MSV-Hidden class so we can style
    // those badges differently, to remind us which ones mean what!
    //
    // // //
    {
      const css = FM.el(
        'style',
        { type: 'text/css' },
        [ '.rjbs-MSV-Workflow .v-MailboxSource-badge { background-color: #e3d8f0; color: #000; padding: 0 0.35em; border-radius: 7px; }' ],
      );
      document.body.appendChild(css);

      FM.classes.Mailbox.prototype.badgeProperty = function () {
        const role = this.get('role');

        if ( role === 'drafts' ) return 'totalEmails';
        if ( role === 'archive' || role === 'sent' || role === 'trash' || role === 'snoozed' ) {
          return null;
        }

        const forceEmail = this.get('isShared') && !this.get('isSeenShared');

        // No easy reference to HIDE_IF_EMPTY so use hardcoded value
        if ( this.get('hidden') === 3 || role === 'inbox' ) {
          return forceEmail ? 'totalEmails' : 'total';
        }

        return forceEmail ? 'unreadEmails' : 'unread';
      }.property( 'role', 'isShared', 'isSeenShared', 'hidden' );

      FM.store.getAll(FM.classes.Mailbox).forEach(
        mailbox => mailbox.computedPropertyDidChange('badgeProperty')
      );

      FM.classes.MailboxSourceView.prototype.className = function () {
        const role = this.get( 'content' ).get( 'role' );
        const isCollapsed = !this.get( 'hasSubfolders' ) || this.get( 'isCollapsed' );
        const isWorkflow  =  this.get('content').get('hidden') === 3 || role === 'inbox';

        return 'v-MailboxSource' +
        ( role ? ' v-MailboxSource--' + role : '' ) +
        ( isWorkflow ? ' rjbs-MSV-Workflow' : '' ) +
        ( isCollapsed ? '' : ' is-expanded' ) +
        ( isCollapsed && this.get( 'hasUnreadChildren' ) ? ' u-bold' : '' );
      }.property( 'hasSubfolders', 'isCollapsed', 'hasUnreadChildren' );

      getViewsByClass(FM.classes.MailboxSourceView).forEach(
        view => view.computedPropertyDidChange('className')
      );
    }

    const stylize = (text, bg, border) => {
      return (e) => {
        if (bg   !== undefined) e.style.backgroundColor = bg;
        if (text !== undefined) e.style.color = text;

        if (border !== undefined) {
          if (border === null) {
            e.style.border = 'none';
          } else {
            e.style.border = '1px solid';
            e.style.borderColor = border;
            e.style.borderRadius = '4px';
          }
        }
      }
    };

    const clippy = {
      text: {
        cycle: 0,
        range: null,
        opts : [ '#a00', '#a0a', '#3b874b', '#d68b00', '#43219c', null ],
      },
      block: {
        cycle: 0,
        range: null,
        opts : [
          stylize('#54365e', '#dacae0'),
          stylize('#9c6500', '#f5fca7'),
          stylize('#275731', '#c3e0c9'),
          stylize(null,       null),
        ],
      },
      callout: {
        cycle: 0,
        range: null,
        opts : [
          // Success
          stylize('#285A37', '#F3F8F5', '#B9D8C2'),

          // Critical: fbf2f4
          stylize('#78202E', '#FBF2F4', '#EAB4BC'),

          // Warning : fff8e6
          stylize('#997B22', '#FFF8E6', '#FFECB4'),

          // Informative: f2f7fb
          stylize('#1F5077', '#F2F7FB', '#B2D1EA'),
        ],
      },
      nextFor: function (key, range) {
        const state = this[key];
        state.cycle = (state.range && (range.compareBoundaryPoints(Range.END_TO_END, state.range) == 0))
        ? ((state.cycle + 1) % state.opts.length)
        : 0;

        return state.opts[ state.cycle ];
      },
    };

    const getEditor = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("Fastamper:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      return editorViews[0].editor;
    };

    const krazyKolour = () => {
      let editor = getEditor();
      if (editor === null) return null;

      const closestSelector = 'div[data-rjbs-callout], div[class$="rjbs-callout"]';

      const range = editor.getSelection();
      if (range.collapsed) {
        const callout = (range.startContainer instanceof Element)
          ? range.startContainer.closest(closestSelector)
          : range.startContainer.parentElement.closest(closestSelector);

        if (callout) {
          const munger = clippy.nextFor('callout', range);
          munger(callout);
          clippy.callout.range = editor.getSelection();
          return null;
        }

        const quote = (range.startContainer instanceof Element)
          ? range.startContainer.closest('blockquote')
          : range.startContainer.parentElement.closest('blockquote');

        if (! quote) {
          console.log("Not inside a callout or blockquote.");
          return null;
        }

        const munger = clippy.nextFor('block', range);
        munger(quote);
        clippy.block.range = editor.getSelection();
      } else {
        const color = clippy.nextFor('text', range);

        editor.setTextColor( color );
        clippy.text.range = editor.getSelection();
      }
    };

    const makeDetails = () => {
      let editor = getEditor();
      if (editor === null) return null;

      editor.modifyBlocks((frag) => {
        console.log(frag);
        let didSummary = false;

        const details = document.createElement("details");
        details.setAttribute('open', 'open');
        details.style.border = "1px black solid";
        details.style.padding = "0.5rem 1rem";
        details.style.borderRadius = "4px";

        // I liked the idea of giving this some kind of slightly tinted
        // background, but this is too dark and I don't feel like thinking
        // about dark mode. -- rjbs, 2022-06-11
        // details.style.backgroundColor = '#80808080';

        for (let outer of frag.childNodes) {
          if (! didSummary) {
            if (outer.nodeType == Node.TEXT_NODE ||
                (outer.nodeType == Node.ELEMENT_NODE && outer.tagName == 'DIV')
            ) {
              const summary = document.createElement("summary");
              summary.style.fontWeight = 'bold';

              for (let n of outer.childNodes) {
                summary.appendChild(n.cloneNode(true));
              }
              outer = summary;
            }
            didSummary = true;
            details.appendChild(outer.cloneNode(true));

            // Absurd. -- rjbs, 2022-06-11
            const spacer = FM.el('p', {}, [ '\xA0' ]);
            spacer.style.fontSize = '25%';
            details.appendChild(spacer);

            continue;
          }

          details.appendChild(outer.cloneNode(true));
        }

        return details;
      });
    };

    const makeCallout = () => {
      let editor = getEditor();
      if (editor === null) return null;

      editor.modifyBlocks((frag) => {
        console.log(frag);

        const callout = document.createElement("div");
        callout.className = 'rjbs-callout';
        callout.setAttribute('data-rjbs-callout', 1);
        callout.style.padding = "1em";
        callout.style.fontWeight = "bold";

        clippy.callout.opts.at(-1)(callout);

        // emoji CSS:     float:left;
        //                font-size:150%;
        //                margin-right:0.75em;
        const emojiDiv = document.createElement("div");
        emojiDiv.style.float    = 'left';
        emojiDiv.style.fontSize = '150%';
        emojiDiv.style.marginRight = '0.75em';
        emojiDiv.style.marginTop = '-0.25em';

        emojiDiv.appendChild( document.createTextNode("👷🏽‍♂️") );

        callout.appendChild(emojiDiv);

        callout.appendChild(frag);

        return callout;
      });
    };

    const ensureIndentWrapper = (frag) => {
      const closestSelector = 'div[data-rjbs-indent], div[class$="rjbs-indent"]';
      let wrapper = frag.querySelector('*').closest(closestSelector);
      let created = false;

      if (! wrapper) {
        wrapper = document.createElement("div");
        wrapper.className = 'rjbs-indent';
        wrapper.setAttribute('data-rjbs-indent', 1);
        wrapper.style.marginLeft = '0px';
        wrapper.appendChild(frag);
        created  = true;
      }

      return { wrapper, created }
    };

    const doIndent = () => {
      let editor = getEditor();
      if (editor === null) return null;

      editor.modifyBlocks((frag) => {
        let { wrapper, created } = ensureIndentWrapper(frag);
        let toReturn  = created ? wrapper : frag;

        let px = parseInt(wrapper.style.marginLeft) || 0;
        px += 40;
        wrapper.style.marginLeft = px + "px";

        return toReturn;
      });
    };

    const doOutdent = () => {
      let editor = getEditor();
      if (editor === null) return null;

      editor.modifyBlocks((frag) => {
        let { wrapper, created } = ensureIndentWrapper(frag);
        let toReturn  = created ? wrapper : frag;

        let px = parseInt(wrapper.style.marginLeft) || 0;
        px -= 40;
        if (px < 0) px = 0;
        wrapper.style.marginLeft = px + "px";

        return toReturn;
      });
    };

    const macros = new Map;

    macros.set(
      (/(BAK|CLI|CYR|DSC|MGMT|MKT|PLAT|PLU|PROD|SUP)-([0-9]+)/i),
      (editor, match) => {
        const url = `https://linear.app/fastmail/issue/${match[1].toUpperCase()}-${match[2]}`;
        editor.makeLink(url);
      }
    );

    macros.set(
      (/^hm!([0-9]+)$/),
      (editor, match) => {
        const url = `https://gitlab.fm/fastmail/hm/-/merge_requests/${match[1]}`;
        editor.makeLink(url);
      }
    );

    macros.set(
      (/^pm:((([A-Za-z0-9]+)::)*([A-Za-z0-9]+))$/),
      (editor, match) => {
        const url = `https://metacpan.org/pod/${match[1]}`;
        const html = `<a href='${url}'>${match[1]}</a>`;
        editor.insertHTML(html);
      }
    );

    macros.set(
      (/^dist:((([A-Za-z0-9]+)-)*([A-Za-z0-9]+))$/),
      (editor, match) => {
        const url = `https://metacpan.org/dist/${match[1]}`;
        const html = `<a href='${url}'>${match[1]}</a>`;
        editor.insertHTML(html);
      }
    );

    const expandMacros = () => {
      let editor = getEditor();
      if (editor === null) return null;

      const range = editor.getSelection();
      if (range.collapsed) {
        // Get the element we're inside of.  If it's a text node, great.  If
        // not, give up.
        if (! range.anchorNode instanceof Text) return;

        // Okay, we're in text.  Executive decision:  macros must be runs of
        // non-whitespace.  So we expand outward to include the current run of
        // non-whitespace.
        const lhs = range.startContainer.textContent.substring(0, range.startOffset);
        const rhs = range.startContainer.textContent.substring(range.startOffset);

        const lhs_match = lhs.match(/(\S+)$/);
        const rhs_match = rhs.match(/^(\S+)/);

        // If both sides of the caret are whitespace, give up.
        if (! lhs_match && ! rhs_match) return;

        const moveLeft  = lhs_match ? lhs_match[1].length : 0;
        const moveRight = rhs_match ? rhs_match[1].length : 0;

        const newRange = range.cloneRange();
        newRange.setStart(range.startContainer, range.startOffset - moveLeft);
        newRange.setEnd(range.startContainer,   range.startOffset + moveRight);

        editor.setSelection(newRange);
      }

      const text = editor.getSelectedText();

      for (const [ regex, fn ] of macros) {
        const match = text.match(regex);
        if (match) {
          fn(editor, match);
          break;
        }
      }

      return;
    };

    // // //
    //
    // KEYBOARD SHORTCUTS
    //
    // // //

    // shortcut: given a keystroke, register a shortcut to call a function
    const shortcut = (keystroke, fn) => {
      FM.ViewEventsController.kbShortcuts.register(keystroke, { do: fn }, 'do');
    };

    // What view of the mailbox?
    // 1 - All mail in mailbox
    // 2 - All mail in mailbox *and* Inbox
    // 3 - Unread mail in mailbox
    shortcut('1', () => getMail().set('mailboxFilter', ''));
    shortcut('2', () => getMail().set('mailboxFilter', 'inbox'));
    shortcut('3', () => getMail().set('mailboxFilter', 'unread'));

    // I hate these shortcuts.
    shortcut('4', () => {
      const mailboxes = FM.store.getAll(FM.classes.Mailbox);
      getMail().goSource(
        FM.findMailbox(mailboxes, 'Staff Mail to Me'),
        null,
        null,
        'inbox'
      );
    });

    shortcut('5', () => {
      const mailboxes = FM.store.getAll(FM.classes.Mailbox);
      getMail().goSource(
        FM.findMailbox(mailboxes, 'Outsiders'),
        null,
        null,
        'inbox'
      );
    });

    shortcut('6', () => {
      getMail().goSource(
        null,
        'in:"Fm Tx.*" AND in:inbox',
        true,
        null
      );
    });

    shortcut('7', () => {
      const mailboxes = FM.store.getAll(FM.classes.Mailbox);
      getMail().goSource(
        FM.findMailbox(mailboxes, 'Group Mail'),
        null,
        null,
        'inbox'
      );
    });

    shortcut('Cmd-Shift-G', () => getMail().toggle('searchIsGlobal'));

    // Display-related preferences
    shortcut('Cmd-Shift-2', () => FM.preferences.toggle('enableConversations'));
    shortcut('Cmd-Shift-D', () => FM.preferences.toggle('showSidebar'));
    shortcut('Cmd-Shift-P', () => FM.preferences.toggle('showReadingPane'));

    shortcut(
      'Cmd-Shift-L',
      () => FM.preferences.set(
        'themeAppearance',
        FM.preferences.get('themeAppearance') === 'light' ? 'dark' : 'light'
      )
    );

    // Editor shortcuts
    shortcut('Cmd-Shift-K', krazyKolour);

    shortcut('Cmd-Shift-.', makeDetails);
    shortcut('Cmd-Shift-1', makeCallout);

    shortcut('Alt-Cmd-0', doIndent);
    shortcut('Alt-Cmd-9', doOutdent);

    shortcut('Alt-Cmd-Enter', expandMacros);
  });
  observer.observe(document.body, { childList: true });
})();
