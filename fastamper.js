// ==UserScript==
// @name         Fastmail Shortcuts
// @namespace    http://tampermonkey.net/
// @version      2022-06-09
// @description  mouse less, keyboard more
// @author       rjbs
// @match        https://*.fastmail.com/*
// @grant        none
// ==/UserScript==

(function() {
  'use strict';
  const observer = new MutationObserver(() => {
    if (document.getElementById('bootstrap-page')) {
      return;
    }
    observer.disconnect();

    const css = FM.el(
      'style',
      { type: 'text/css' },
      [ '.rjbs-MSV-Hidden-3 .v-MailboxSource-badge { background-color: #e3d8f0; color: #000; padding: 0 0.35em; border-radius: 7px; }' ],
    );
    document.body.appendChild(css);

    const shortcut = (keystroke, fn) => {
      FM.ViewEventsController.kbShortcuts.register(keystroke, { do: fn }, 'do');
    };

    shortcut(
      'Cmd-Shift-L',
      () => {
        if (FM.preferences.get('themeAppearance') === 'light') {
          FM.preferences.set('themeAppearance', 'dark');
        } else {
          FM.preferences.set('themeAppearance', 'light');
        }
      },
    );

    const mail = FM.router.getAppController('mail');
    shortcut('<', () => mail.sources.get('sourceGroups')[0].content.forEach(s => s.set('isCollapsed', true)));
    shortcut('>', () => mail.sources.get('sourceGroups')[0].content.forEach(s => s.set('isCollapsed', false)));

    shortcut('1', () => mail.set('mailboxFilter', ''));
    shortcut('2', () => mail.set('mailboxFilter', 'inbox'));
    shortcut('3', () => mail.set('mailboxFilter', 'unread'));

    shortcut('Cmd-Shift-2', () => FM.preferences.toggle('enableConversations'));
    shortcut('Cmd-Shift-D', () => FM.preferences.toggle('showSidebar'));
    shortcut('Cmd-Shift-G', () => mail.toggle('searchIsGlobal'));
    shortcut('Cmd-Shift-P', () => FM.preferences.toggle('showReadingPane'));

    const stylize = (bg, text, border) => {
      return (e) => {
        if (bg !== null)     e.style.backgroundColor = bg;
        if (text   !== null) e.style.color           = text;
        if (border !== null) {
          e.style.border = '1px solid';
          e.style.borderColor = border;
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
          (e) => { e.style.backgroundColor = '#dacae0'; e.style.color = '#54365e'; },
          (e) => { e.style.backgroundColor = '#f5fca7'; e.style.color = '#9c6500'; },
          (e) => { e.style.backgroundColor = '#c3e0c9'; e.style.color = '#275731'; },
          (e) => { e.style.backgroundColor = null; e.style.color = null; },
        ],
      },
      callout: {
        cycle: 0,
        range: null,
        opts : [
          // Success
          stylize('#F3F8F5', '#285A37', '#B9D8C2'),

          // Critical: fbf2f4
          stylize('#FBF2F4', '#78202E', '#EAB4BC'),

          // Warning : fff8e6
          stylize('#FFF8E6', '#997B22', '#FFECB4'),

          // Informative: f2f7fb
          stylize('#F2F7FB', '#1F5077', '#B2D1EA'),
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

    const getViewsByClass = (viewClass) => {
      return Object.values(FM.activeViews).filter(view => view instanceof viewClass);
    }

    const krazyKolour = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("RJBS:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      let editor = editorViews[0].editor;

      if (! editor) {
        console.log("No editor?  I give up.");
        return null;
      }

      const range = editor.getSelection();
      if (range.collapsed) {
        const callout = (range.startContainer instanceof Element)
          ? range.startContainer.closest('div[data-rjbscallout="1"]')
          : range.startContainer.parentElement.closest('div[data-rjbscallout="1"]');

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

        editor.setTextColour( color );
        clippy.text.range = editor.getSelection();
      }
    };

    shortcut('Cmd-Shift-K', krazyKolour);

    const encloseDisclose = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("RJBS:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      let editor = editorViews[0].editor;

      editor.modifyBlocks((frag) => {
        console.log(frag);
        let didSummary = false;

        const details = document.createElement("details");
        details.style.border = "1px black solid";
        details.style.padding = "0.5rem 1rem";

        for (let outer of frag.childNodes) {
          if (! didSummary) {
            if (outer.nodeType == Node.TEXT_NODE ||
                (outer.nodeType == Node.ELEMENT_NODE && outer.tagName == 'DIV')
            ) {
              const summary = document.createElement("summary");
              for (let n of outer.childNodes) {
                summary.appendChild(n.cloneNode(true));
              }
              outer = summary;
            }
            didSummary = true;
          }
          details.appendChild(outer.cloneNode(true));
        }

        return details;
      });
    };

    const makeCallout = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("RJBS:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      let editor = editorViews[0].editor;

      editor.modifyBlocks((frag) => {
        console.log(frag);

        const callout = document.createElement("div");
        callout.className = 'callout';
        callout.setAttribute('data-rjbscallout', 1);
        callout.style.borderRadius = '4px';
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

    const doIndent = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("RJBS:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      let editor = editorViews[0].editor;

      editor.modifyBlocks((frag) => {
        let indentDiv = frag.querySelector('*').closest('div[data-indentwrapper="1"]');
        let toReturn  = frag;

        if (! indentDiv) {
          console.log("creating a new data-indentwrapper");
          indentDiv = document.createElement("div");
          indentDiv.setAttribute('data-indentwrapper', 1);
          indentDiv.style.marginLeft = '0px';
          indentDiv.appendChild(frag);
          toReturn = indentDiv;
        }

        let px = parseInt(indentDiv.style.marginLeft) || 0;
        px += 40;
        indentDiv.style.marginLeft = px + "px";

        return toReturn;
      });
    };

    const doOutdent = () => {
      let editorViews = getViewsByClass(FM.classes.RichTextView);
      if (editorViews.length != 1) {
        console("RJBS:  Wanted exactly one v-RichText but got " + editorViews.length + ".");
        return null;
      }

      let editor = editorViews[0].editor;

      editor.modifyBlocks((frag) => {
        let indentDiv = frag.querySelector('*').closest('div[data-indentwrapper="1"]');
        let toReturn  = frag;

        if (! indentDiv) {
          console.log("creating a new data-indentwrapper");
          indentDiv = document.createElement("div");
          indentDiv.setAttribute('data-indentwrapper', 1);
          indentDiv.style.marginLeft = '0px';
          indentDiv.appendChild(frag);
          toReturn = indentDiv;
        }

        let px = parseInt(indentDiv.style.marginLeft) || 0;
        px -= 40;
        if (px < 0) px = 0;
        indentDiv.style.marginLeft = px + "px";

        return toReturn;
      });
    };

    shortcut('Cmd-Shift-D', encloseDisclose);
    shortcut('Cmd-Shift-Z', makeCallout);
    shortcut('Alt-Cmd-0', doIndent);
    shortcut('Alt-Cmd-9', doOutdent);

    FM.classes.Mailbox.prototype.badgeProperty = function () {
      var role = this.get('role');

      if ( role === 'drafts' ) return 'totalEmails';
      if ( role === 'archive' || role === 'sent' || role === 'trash' || role === 'snoozed' ) {
        return null;
      }

      var forceEmail = this.get('isShared') && !this.get('isSeenShared');

      // No easy reference to HIDE_IF_EMPTY so use hardcoded value
      if ( this.get('hidden') === 3) {
        return forceEmail ? 'totalEmails' : 'total';
      }

      return forceEmail ? 'unreadEmails' : 'unread';
    }.property( 'role', 'isShared', 'isSeenShared', 'hidden' );

    FM.store.getAll(FM.classes.Mailbox).forEach(mailbox => mailbox.computedPropertyDidChange('badgeProperty'));

    FM.classes.MailboxSourceView.prototype.className = function () {
      var role = this.get( 'content' ).get( 'role' );
      var isCollapsed = !this.get( 'hasSubfolders' ) || this.get( 'isCollapsed' );

      return 'v-MailboxSource' +
      ( role ? ' v-MailboxSource--' + role : '' ) +
      ( ' rjbs-MSV-Hidden-' + this.get('content').get('hidden') ) +
      ( isCollapsed ? '' : ' is-expanded' ) +
      ( isCollapsed && this.get( 'hasUnreadChildren' ) ? ' u-bold' : '' );
    }.property( 'hasSubfolders', 'isCollapsed', 'hasUnreadChildren' );

    getViewsByClass(FM.classes.MailboxSourceView).forEach(
      view => view.computedPropertyDidChange('className')
    );
  });
  observer.observe(document.body, { childList: true });
})();
