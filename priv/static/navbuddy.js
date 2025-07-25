/*!
 * NavBuddy - Advanced Configurable Navigation Component for Phoenix LiveView
 * Copyright (c) 2025 Rogers Sangale
 * Licensed under MIT
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = global || self, global.NavBuddy = factory());
}(this, (function () { 'use strict';

  /**
   * NavBuddy - Advanced navigation functionality for Phoenix LiveView
   */
  class NavBuddy {
    constructor(element, options = {}) {
      this.element = element;
      this.options = {
        autoInit: true,
        smartPositioning: true,
        keyboardNavigation: true,
        touchGestures: true,
        analytics: false,
        autoCloseDelay: 300,
        focusManagement: true,
        ...options
      };

      this.state = {
        activeDropdown: null,
        activeMegaMenu: null,
        mobileOpen: false,
        currentFocus: null,
        touchStartY: 0,
        isReducedMotion: false
      };

      this.timers = {
        autoClose: null,
        debounce: null
      };

      this.init();
    }

    /**
     * Initialize NavBuddy functionality
     */
    init() {
      if (!this.element) {
        console.warn('NavBuddy: No element provided');
        return;
      }

      this.detectFeatures();
      this.setupEventListeners();
      this.setupKeyboardNavigation();
      this.setupTouchGestures();
      this.setupPhoenixLiveView();
      this.setupSmartPositioning();
      this.setupAccessibility();

      if (this.options.autoInit) {
        this.element.classList.add('navbuddy-initialized');
        this.trackEvent('initialized');
      }
    }

    /**
     * Detect browser features and user preferences
     */
    detectFeatures() {
      // Detect reduced motion preference
      this.state.isReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      
      // Detect touch support
      this.hasTouchSupport = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
      
      // Detect mobile viewport
      this.isMobile = window.innerWidth <= this.getMobileBreakpoint();
      
      // Listen for viewport changes
      window.addEventListener('resize', this.debounce(() => {
        this.isMobile = window.innerWidth <= this.getMobileBreakpoint();
        this.handleViewportChange();
      }, 150));
    }

    /**
     * Get mobile breakpoint from CSS or config
     */
    getMobileBreakpoint() {
      const cssBreakpoint = getComputedStyle(document.documentElement)
        .getPropertyValue('--navbuddy-mobile-breakpoint');
      return parseInt(cssBreakpoint) || 768;
    }

    /**
     * Setup main event listeners
     */
    setupEventListeners() {
      // Dropdown triggers
      this.element.addEventListener('click', this.handleClick.bind(this));
      this.element.addEventListener('mouseenter', this.handleMouseEnter.bind(this), true);
      this.element.addEventListener('mouseleave', this.handleMouseLeave.bind(this), true);
      
      // Mobile toggle
      const mobileToggle = this.element.querySelector('.navbuddy-mobile-toggle');
      if (mobileToggle) {
        mobileToggle.addEventListener('click', this.toggleMobileNav.bind(this));
      }

      // Close menus when clicking outside
      document.addEventListener('click', (e) => {
        if (!this.element.contains(e.target)) {
          this.closeAllMenus();
        }
      });

      // Handle escape key globally
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
          this.closeAllMenus();
          this.trackEvent('escape_close');
        }
      });

      // Handle focus changes
      document.addEventListener('focusin', this.handleFocusIn.bind(this));
    }

    /**
     * Handle click events
     */
    handleClick(e) {
      const trigger = e.target.closest('.navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
      if (!trigger) return;

      e.preventDefault();
      e.stopPropagation();

      const isDropdown = trigger.classList.contains('navbuddy-dropdown-trigger');
      const isMegaMenu = trigger.classList.contains('navbuddy-mega-trigger');
      const itemId = trigger.closest('.navbuddy-nav-item-wrapper')?.dataset.itemId;

      if (!itemId) return;

      if (this.isClickTrigger()) {
        if (isDropdown) {
          this.toggleDropdown(itemId);
        } else if (isMegaMenu) {
          this.toggleMegaMenu(itemId);
        }
      }

      this.trackEvent('trigger_click', { itemId, type: isDropdown ? 'dropdown' : 'mega_menu' });
    }

    /**
     * Handle mouse enter events
     */
    handleMouseEnter(e) {
      if (this.isMobile || this.isClickTrigger()) return;

      const trigger = e.target.closest('.navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
      if (!trigger) return;

      const isDropdown = trigger.classList.contains('navbuddy-dropdown-trigger');
      const isMegaMenu = trigger.classList.contains('navbuddy-mega-trigger');
      const itemId = trigger.closest('.navbuddy-nav-item-wrapper')?.dataset.itemId;

      if (!itemId) return;

      // Clear any auto-close timer
      this.clearTimer('autoClose');

      if (isDropdown) {
        this.openDropdown(itemId);
      } else if (isMegaMenu) {
        this.openMegaMenu(itemId);
      }
    }

    /**
     * Handle mouse leave events
     */
    handleMouseLeave(e) {
      if (this.isMobile || this.isClickTrigger()) return;

      const wrapper = e.target.closest('.navbuddy-nav-item-wrapper');
      if (!wrapper) return;

      // Start auto-close timer
      this.timers.autoClose = setTimeout(() => {
        this.closeAllMenus();
      }, this.options.autoCloseDelay);
    }

    /**
     * Toggle dropdown menu
     */
    toggleDropdown(itemId) {
      if (this.state.activeDropdown === itemId) {
        this.closeDropdown(itemId);
      } else {
        this.openDropdown(itemId);
      }
    }

    /**
     * Open dropdown menu
     */
    openDropdown(itemId) {
      this.closeAllMenus();
      
      const dropdown = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-dropdown`);
      const trigger = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-dropdown-trigger`);
      
      if (!dropdown || !trigger) return;

      this.state.activeDropdown = itemId;
      dropdown.classList.add('open');
      trigger.setAttribute('aria-expanded', 'true');

      if (this.options.smartPositioning) {
        this.adjustDropdownPosition(dropdown);
      }

      this.trackEvent('dropdown_open', { itemId });
      this.sendPhoenixEvent('navbuddy:dropdown_open', { id: itemId });
    }

    /**
     * Close dropdown menu
     */
    closeDropdown(itemId) {
      const dropdown = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-dropdown`);
      const trigger = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-dropdown-trigger`);
      
      if (!dropdown || !trigger) return;

      this.state.activeDropdown = null;
      dropdown.classList.remove('open');
      trigger.setAttribute('aria-expanded', 'false');

      this.trackEvent('dropdown_close', { itemId });
      this.sendPhoenixEvent('navbuddy:dropdown_close', { id: itemId });
    }

    /**
     * Toggle mega menu
     */
    toggleMegaMenu(itemId) {
      if (this.state.activeMegaMenu === itemId) {
        this.closeMegaMenu(itemId);
      } else {
        this.openMegaMenu(itemId);
      }
    }

    /**
     * Open mega menu
     */
    openMegaMenu(itemId) {
      this.closeAllMenus();
      
      const megaMenu = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-mega-menu`);
      const trigger = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-mega-trigger`);
      
      if (!megaMenu || !trigger) return;

      this.state.activeMegaMenu = itemId;
      megaMenu.classList.add('open');
      trigger.setAttribute('aria-expanded', 'true');

      if (this.options.smartPositioning) {
        this.adjustMegaMenuPosition(megaMenu);
      }

      this.trackEvent('mega_menu_open', { itemId });
      this.sendPhoenixEvent('navbuddy:mega_menu_open', { id: itemId });
    }

    /**
     * Close mega menu
     */
    closeMegaMenu(itemId) {
      const megaMenu = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-mega-menu`);
      const trigger = this.element.querySelector(`[data-item-id="${itemId}"] .navbuddy-mega-trigger`);
      
      if (!megaMenu || !trigger) return;

      this.state.activeMegaMenu = null;
      megaMenu.classList.remove('open');
      trigger.setAttribute('aria-expanded', 'false');

      this.trackEvent('mega_menu_close', { itemId });
      this.sendPhoenixEvent('navbuddy:mega_menu_close', { id: itemId });
    }

    /**
     * Close all open menus
     */
    closeAllMenus() {
      // Close dropdowns
      this.element.querySelectorAll('.navbuddy-dropdown.open').forEach(dropdown => {
        dropdown.classList.remove('open');
      });

      // Close mega menus
      this.element.querySelectorAll('.navbuddy-mega-menu.open').forEach(megaMenu => {
        megaMenu.classList.remove('open');
      });

      // Reset aria-expanded attributes
      this.element.querySelectorAll('[aria-expanded="true"]').forEach(trigger => {
        trigger.setAttribute('aria-expanded', 'false');
      });

      this.state.activeDropdown = null;
      this.state.activeMegaMenu = null;
      this.clearTimer('autoClose');
    }

    /**
     * Toggle mobile navigation
     */
    toggleMobileNav() {
      this.state.mobileOpen = !this.state.mobileOpen;
      
      this.element.classList.toggle('navbuddy-mobile-open', this.state.mobileOpen);
      
      const toggle = this.element.querySelector('.navbuddy-mobile-toggle');
      if (toggle) {
        toggle.setAttribute('aria-expanded', this.state.mobileOpen);
      }

      // Manage body scroll
      if (this.state.mobileOpen) {
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = '';
      }

      this.trackEvent('mobile_toggle', { state: this.state.mobileOpen ? 'open' : 'close' });
      this.sendPhoenixEvent('navbuddy:mobile_toggle', { open: this.state.mobileOpen });
    }

    /**
     * Setup keyboard navigation
     */
    setupKeyboardNavigation() {
      if (!this.options.keyboardNavigation) return;

      this.element.addEventListener('keydown', (e) => {
        this.handleKeyboardNavigation(e);
      });
    }

    /**
     * Handle keyboard navigation
     */
    handleKeyboardNavigation(e) {
      const { key } = e;
      const activeElement = document.activeElement;
      const isInNav = this.element.contains(activeElement);

      if (!isInNav) return;

      switch (key) {
        case 'ArrowDown':
          e.preventDefault();
          this.navigateDown(activeElement);
          break;
        case 'ArrowUp':
          e.preventDefault();
          this.navigateUp(activeElement);
          break;
        case 'ArrowLeft':
          e.preventDefault();
          this.navigateLeft(activeElement);
          break;
        case 'ArrowRight':
          e.preventDefault();
          this.navigateRight(activeElement);
          break;
        case 'Enter':
        case ' ':
          e.preventDefault();
          this.activateElement(activeElement);
          break;
        case 'Escape':
          e.preventDefault();
          this.closeAllMenus();
          this.focusMainNav();
          break;
        case 'Home':
          e.preventDefault();
          this.focusFirst();
          break;
        case 'End':
          e.preventDefault();
          this.focusLast();
          break;
      }

      this.trackEvent('keyboard_navigation', { key, context: this.getNavigationContext(activeElement) });
    }

    /**
     * Navigate down in the menu
     */
    navigateDown(current) {
      const currentItem = current.closest('.navbuddy-nav-item, .navbuddy-dropdown-item, .navbuddy-mega-menu-item');
      if (!currentItem) return;

      // If current item has a dropdown/mega menu, open it and focus first item
      const hasDropdown = currentItem.closest('.navbuddy-nav-item-wrapper')?.querySelector('.navbuddy-dropdown');
      const hasMegaMenu = currentItem.closest('.navbuddy-nav-item-wrapper')?.querySelector('.navbuddy-mega-menu');

      if (hasDropdown && !hasDropdown.classList.contains('open')) {
        const itemId = currentItem.closest('.navbuddy-nav-item-wrapper').dataset.itemId;
        this.openDropdown(itemId);
        setTimeout(() => {
          const firstLink = hasDropdown.querySelector('.navbuddy-nav-link');
          if (firstLink) firstLink.focus();
        }, 50);
        return;
      }

      if (hasMegaMenu && !hasMegaMenu.classList.contains('open')) {
        const itemId = currentItem.closest('.navbuddy-nav-item-wrapper').dataset.itemId;
        this.openMegaMenu(itemId);
        setTimeout(() => {
          const firstLink = hasMegaMenu.querySelector('.navbuddy-nav-link');
          if (firstLink) firstLink.focus();
        }, 50);
        return;
      }

      // Otherwise, focus next sibling
      const nextItem = currentItem.nextElementSibling;
      if (nextItem) {
        const nextLink = nextItem.querySelector('.navbuddy-nav-link, .navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
        if (nextLink) nextLink.focus();
      }
    }

    /**
     * Navigate up in the menu
     */
    navigateUp(current) {
      const currentItem = current.closest('.navbuddy-nav-item, .navbuddy-dropdown-item, .navbuddy-mega-menu-item');
      if (!currentItem) return;

      const prevItem = currentItem.previousElementSibling;
      if (prevItem) {
        const prevLink = prevItem.querySelector('.navbuddy-nav-link, .navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
        if (prevLink) prevLink.focus();
      } else {
        // If at top of dropdown/mega menu, focus parent trigger
        const parentWrapper = currentItem.closest('.navbuddy-dropdown, .navbuddy-mega-menu')?.closest('.navbuddy-nav-item-wrapper');
        if (parentWrapper) {
          const parentTrigger = parentWrapper.querySelector('.navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
          if (parentTrigger) parentTrigger.focus();
        }
      }
    }

    /**
     * Navigate left in the menu
     */
    navigateLeft(current) {
      // Close current dropdown/mega menu and focus previous main nav item
      this.closeAllMenus();
      
      const currentMainItem = current.closest('.navbuddy-nav-item');
      if (currentMainItem) {
        const prevMainItem = currentMainItem.previousElementSibling;
        if (prevMainItem) {
          const prevLink = prevMainItem.querySelector('.navbuddy-nav-link, .navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
          if (prevLink) prevLink.focus();
        }
      }
    }

    /**
     * Navigate right in the menu
     */
    navigateRight(current) {
      // Close current dropdown/mega menu and focus next main nav item
      this.closeAllMenus();
      
      const currentMainItem = current.closest('.navbuddy-nav-item');
      if (currentMainItem) {
        const nextMainItem = currentMainItem.nextElementSibling;
        if (nextMainItem) {
          const nextLink = nextMainItem.querySelector('.navbuddy-nav-link, .navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
          if (nextLink) nextLink.focus();
        }
      }
    }

    /**
     * Activate current element
     */
    activateElement(element) {
      if (element.classList.contains('navbuddy-dropdown-trigger')) {
        const itemId = element.closest('.navbuddy-nav-item-wrapper').dataset.itemId;
        this.toggleDropdown(itemId);
      } else if (element.classList.contains('navbuddy-mega-trigger')) {
        const itemId = element.closest('.navbuddy-nav-item-wrapper').dataset.itemId;
        this.toggleMegaMenu(itemId);
      } else if (element.classList.contains('navbuddy-nav-link')) {
        element.click();
      }
    }

    /**
     * Focus first navigation item
     */
    focusFirst() {
      const firstLink = this.element.querySelector('.navbuddy-nav-link, .navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
      if (firstLink) firstLink.focus();
    }

    /**
     * Focus last navigation item
     */
    focusLast() {
      const links = this.element.querySelectorAll('.navbuddy-nav-link, .navbuddy-dropdown-trigger, .navbuddy-mega-trigger');
      const lastLink = links[links.length - 1];
      if (lastLink) lastLink.focus();
    }

    /**
     * Focus main navigation
     */
    focusMainNav() {
      this.focusFirst();
    }

    /**
     * Setup touch gestures
     */
    setupTouchGestures() {
      if (!this.options.touchGestures || !this.hasTouchSupport) return;

      this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true });
      this.element.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
      this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: true });
    }

    /**
     * Handle touch start
     */
    handleTouchStart(e) {
      this.state.touchStartY = e.touches[0].clientY;
    }

    /**
     * Handle touch move
     */
    handleTouchMove(e) {
      if (!this.state.mobileOpen) return;

      const touchY = e.touches[0].clientY;
      const deltaY = touchY - this.state.touchStartY;

      // Swipe down to close mobile menu
      if (deltaY > 50) {
        e.preventDefault();
        this.toggleMobileNav();
      }
    }

    /**
     * Handle touch end
     */
    handleTouchEnd(e) {
      // Reset touch state
      this.state.touchStartY = 0;
    }

    /**
     * Setup smart positioning
     */
    setupSmartPositioning() {
      if (!this.options.smartPositioning) return;

      // Position adjustments will be called when menus open
      window.addEventListener('scroll', this.debounce(() => {
        this.adjustAllPositions();
      }, 100));
    }

    /**
     * Adjust dropdown position to stay in viewport
     */
    adjustDropdownPosition(dropdown) {
      const rect = dropdown.getBoundingClientRect();
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;

      // Reset positioning classes
      dropdown.classList.remove('position-right', 'position-up');

      // Check if dropdown extends beyond right edge
      if (rect.right > viewportWidth) {
        dropdown.classList.add('position-right');
      }

      // Check if dropdown extends beyond bottom edge
      if (rect.bottom > viewportHeight) {
        dropdown.classList.add('position-up');
      }
    }

    /**
     * Adjust mega menu position to stay in viewport
     */
    adjustMegaMenuPosition(megaMenu) {
      const rect = megaMenu.getBoundingClientRect();
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;

      // Adjust horizontal positioning
      if (rect.left < 0) {
        megaMenu.style.transform = `translateX(${Math.abs(rect.left)}px) translateY(0)`;
      } else if (rect.right > viewportWidth) {
        const overflow = rect.right - viewportWidth;
        megaMenu.style.transform = `translateX(-${overflow}px) translateY(0)`;
      }

      // Adjust vertical positioning if needed
      if (rect.bottom > viewportHeight) {
        megaMenu.classList.add('position-up');
      }
    }

    /**
     * Adjust all open menu positions
     */
    adjustAllPositions() {
      this.element.querySelectorAll('.navbuddy-dropdown.open').forEach(dropdown => {
        this.adjustDropdownPosition(dropdown);
      });

      this.element.querySelectorAll('.navbuddy-mega-menu.open').forEach(megaMenu => {
        this.adjustMegaMenuPosition(megaMenu);
      });
    }

    /**
     * Setup accessibility features
     */
    setupAccessibility() {
      // Add ARIA live region for screen reader announcements
      if (!document.getElementById('navbuddy-live-region')) {
        const liveRegion = document.createElement('div');
        liveRegion.id = 'navbuddy-live-region';
        liveRegion.setAttribute('aria-live', 'polite');
        liveRegion.setAttribute('aria-atomic', 'true');
        liveRegion.className = 'navbuddy-sr-only';
        document.body.appendChild(liveRegion);
      }

      // Ensure proper ARIA attributes
      this.updateAriaAttributes();
    }

    /**
     * Update ARIA attributes
     */
    updateAriaAttributes() {
      // Set up dropdown relationships
      this.element.querySelectorAll('.navbuddy-dropdown-trigger').forEach(trigger => {
        const wrapper = trigger.closest('.navbuddy-nav-item-wrapper');
        const dropdown = wrapper?.querySelector('.navbuddy-dropdown');
        
        if (dropdown && !dropdown.id) {
          const itemId = wrapper.dataset.itemId;
          dropdown.id = `navbuddy-dropdown-${itemId}`;
          trigger.setAttribute('aria-controls', dropdown.id);
        }
      });

      // Set up mega menu relationships
      this.element.querySelectorAll('.navbuddy-mega-trigger').forEach(trigger => {
        const wrapper = trigger.closest('.navbuddy-nav-item-wrapper');
        const megaMenu = wrapper?.querySelector('.navbuddy-mega-menu');
        
        if (megaMenu && !megaMenu.id) {
          const itemId = wrapper.dataset.itemId;
          megaMenu.id = `navbuddy-mega-menu-${itemId}`;
          trigger.setAttribute('aria-controls', megaMenu.id);
        }
      });
    }

    /**
     * Announce to screen readers
     */
    announceToScreenReaders(message) {
      const liveRegion = document.getElementById('navbuddy-live-region');
      if (liveRegion) {
        liveRegion.textContent = message;
      }
    }

    /**
     * Setup Phoenix LiveView integration
     */
    setupPhoenixLiveView() {
      // Listen for Phoenix events
      if (window.liveSocket) {
        this.element.addEventListener('navbuddy:state_change', this.handlePhoenixStateChange.bind(this));
        this.element.addEventListener('navbuddy:config_update', this.handlePhoenixConfigUpdate.bind(this));
      }
    }

    /**
     * Send event to Phoenix LiveView
     */
    sendPhoenixEvent(eventName, payload = {}) {
      if (window.liveSocket && this.element.closest('[phx-*]')) {
        this.element.dispatchEvent(new CustomEvent(eventName, {
          detail: payload,
          bubbles: true
        }));
      }
    }

    /**
     * Handle Phoenix state changes
     */
    handlePhoenixStateChange(e) {
      const { activeDropdown, activeMegaMenu, mobileOpen } = e.detail;

      if (activeDropdown !== this.state.activeDropdown) {
        if (activeDropdown) {
          this.openDropdown(activeDropdown);
        } else if (this.state.activeDropdown) {
          this.closeDropdown(this.state.activeDropdown);
        }
      }

      if (activeMegaMenu !== this.state.activeMegaMenu) {
        if (activeMegaMenu) {
          this.openMegaMenu(activeMegaMenu);
        } else if (this.state.activeMegaMenu) {
          this.closeMegaMenu(this.state.activeMegaMenu);
        }
      }

      if (mobileOpen !== this.state.mobileOpen) {
        this.state.mobileOpen = mobileOpen;
        this.element.classList.toggle('navbuddy-mobile-open', mobileOpen);
      }
    }

    /**
     * Handle Phoenix config updates
     */
    handlePhoenixConfigUpdate(e) {
      const { config } = e.detail;
      
      // Update data attributes
      Object.entries(config).forEach(([key, value]) => {
        this.element.setAttribute(`data-${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`, value);
      });

      // Refresh functionality based on new config
      this.init();
    }

    /**
     * Handle focus changes
     */
    handleFocusIn(e) {
      if (!this.options.focusManagement) return;

      const focusedElement = e.target;
      if (this.element.contains(focusedElement)) {
        this.state.currentFocus = focusedElement;
      }
    }

    /**
     * Handle viewport changes
     */
    handleViewportChange() {
      // Close mobile menu if viewport becomes desktop
      if (!this.isMobile && this.state.mobileOpen) {
        this.toggleMobileNav();
      }

      // Adjust menu positions
      this.adjustAllPositions();

      this.trackEvent('viewport_change', { isMobile: this.isMobile });
    }

    /**
     * Track analytics event
     */
    trackEvent(eventType, data = {}) {
      if (!this.options.analytics) return;

      const event = {
        type: 'navbuddy',
        action: eventType,
        data: {
          ...data,
          timestamp: Date.now(),
          userAgent: navigator.userAgent,
          viewport: {
            width: window.innerWidth,
            height: window.innerHeight
          }
        }
      };

      // Send to Phoenix LiveView if available
      this.sendPhoenixEvent('navbuddy:analytics', event);

      // Send to global analytics if available
      if (window.gtag) {
        window.gtag('event', eventType, {
          event_category: 'navigation',
          event_label: data.itemId || 'unknown',
          custom_map: data
        });
      }

      if (window.analytics && window.analytics.track) {
        window.analytics.track(`NavBuddy ${eventType}`, data);
      }
    }

    /**
     * Get navigation context for current element
     */
    getNavigationContext(element) {
      if (element.closest('.navbuddy-dropdown')) return 'dropdown';
      if (element.closest('.navbuddy-mega-menu')) return 'mega_menu';
      if (element.closest('.navbuddy-nav-list')) return 'main_nav';
      return 'unknown';
    }

    /**
     * Check if using click trigger mode
     */
    isClickTrigger() {
      return this.element.getAttribute('data-dropdown-trigger') === 'click';
    }

    /**
     * Debounce function
     */
    debounce(func, wait) {
      return (...args) => {
        clearTimeout(this.timers.debounce);
        this.timers.debounce = setTimeout(() => func.apply(this, args), wait);
      };
    }

    /**
     * Clear timer
     */
    clearTimer(name) {
      if (this.timers[name]) {
        clearTimeout(this.timers[name]);
        this.timers[name] = null;
      }
    }

    /**
     * Destroy NavBuddy instance
     */
    destroy() {
      // Remove event listeners
      this.element.removeEventListener('click', this.handleClick);
      this.element.removeEventListener('mouseenter', this.handleMouseEnter);
      this.element.removeEventListener('mouseleave', this.handleMouseLeave);

      // Clear timers
      Object.keys(this.timers).forEach(timer => this.clearTimer(timer));

      // Remove classes
      this.element.classList.remove('navbuddy-initialized');

      // Reset state
      this.state = {
        activeDropdown: null,
        activeMegaMenu: null,
        mobileOpen: false,
        currentFocus: null,
        touchStartY: 0
      };

      this.trackEvent('destroyed');
    }

    /**
     * Get current state
     */
    getState() {
      return { ...this.state };
    }

    /**
     * Update options
     */
    updateOptions(newOptions) {
      this.options = { ...this.options, ...newOptions };
      this.init(); // Reinitialize with new options
    }
  }

  /**
   * Auto-initialize NavBuddy on DOM ready
   */
  function autoInit() {
    const navElements = document.querySelectorAll('.navbuddy-nav:not(.navbuddy-initialized)');
    
    navElements.forEach(element => {
      // Get options from data attributes
      const options = {
        smartPositioning: element.dataset.smartPositioning !== 'false',
        keyboardNavigation: element.dataset.keyboardNavigation !== 'false',
        touchGestures: element.dataset.touchGestures !== 'false',
        analytics: element.dataset.analytics === 'true',
        autoCloseDelay: parseInt(element.dataset.autoCloseDelay) || 300
      };

      new NavBuddy(element, options);
    });
  }

  // Auto-initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', autoInit);
  } else {
    autoInit();
  }

  // Re-initialize on Phoenix LiveView updates
  document.addEventListener('phx:update', () => {
    setTimeout(autoInit, 100);
  });

  // Export NavBuddy class
  return NavBuddy;

})));