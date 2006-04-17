;;; -*- Mode: Lisp; -*-

;;;  (c) 2006 David Lichteblau (david@lichteblau.com)

;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Library General Public
;;; License as published by the Free Software Foundation; either
;;; version 2 of the License, or (at your option) any later version.
;;;
;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Library General Public License for more details.
;;;
;;; You should have received a copy of the GNU Library General Public
;;; License along with this library; if not, write to the 
;;; Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
;;; Boston, MA  02111-1307  USA.

(in-package :clim-gtkairo)

(defclass gtkairo-pixmap (climi::mirrored-pixmap) ())

(defun medium-gdkdrawable (medium)
  (mirror-drawable (medium-mirror medium)))

(defun ensure-pixmap-medium (pixmap-sheet)
  (or (climi::pixmap-medium pixmap-sheet)
      (setf (climi::pixmap-medium pixmap-sheet)
	    (make-medium (port pixmap-sheet) pixmap-sheet))))

(defmethod pixmap-depth ((pixmap-sheet gtkairo-pixmap))
  (gdk_drawable_get_depth
   (medium-gdkdrawable (ensure-pixmap-medium pixmap-sheet))))

(defun %medium-copy-area (from-medium from-x from-y width height
			  to-medium to-x to-y)
  (with-gtk ()
    (sync-sheet from-medium)
    (sync-sheet to-medium)
    (let ((from-surface (cairo_get_target (cr from-medium)))
	  (from-drawable (medium-gdkdrawable from-medium))
 	  (to-surface (cairo_get_target (cr to-medium)))
	  (to-drawable (medium-gdkdrawable to-medium)))
      (cairo_surface_flush from-surface)
      (cairo_surface_flush to-surface)
      (let ((gc (gdk_gc_new to-drawable)))
	(gdk_draw_drawable to-drawable
			   gc
			   from-drawable
			   (truncate from-x)
			   (truncate from-y)
			   (truncate to-x)
			   (truncate to-y)
			   (truncate width)
			   (truncate height))
	(gdk_gc_unref gc))
      (cairo_surface_mark_dirty to-surface))))

;;; Wer hat sich denn diese Transformiererei ausgedacht?

(defmethod medium-copy-area
    ((from-medium gtkairo-medium) from-x from-y width height
     (to-medium gtkairo-medium) to-x to-y)
  (climi::with-transformed-position
      ((sheet-native-transformation (medium-sheet from-medium))
       from-x from-y)
    (climi::with-transformed-position
	((sheet-native-transformation (medium-sheet to-medium))
	 to-x to-y)
      (multiple-value-bind (width height)
	  (transform-distance (medium-transformation from-medium)
			      width height)
	(%medium-copy-area from-medium from-x from-y width height
			   to-medium to-x to-y)))))

(defmethod medium-copy-area
    ((from-medium gtkairo-medium) from-x from-y width height
     (to-medium gtkairo-pixmap) to-x to-y)
  (climi::with-transformed-position
      ((sheet-native-transformation (medium-sheet from-medium))
       from-x from-y)
    (%medium-copy-area from-medium from-x from-y width height
		       (ensure-pixmap-medium to-medium) to-x to-y)))

(defmethod medium-copy-area
    ((from-medium gtkairo-pixmap) from-x from-y width height
     (to-medium gtkairo-medium) to-x to-y)
  (climi::with-transformed-position
      ((sheet-native-transformation (medium-sheet to-medium))
       to-x to-y)
    (%medium-copy-area (ensure-pixmap-medium from-medium) from-x from-y
		       width height
		       to-medium to-x to-y)))

(defmethod medium-copy-area
    ((from-medium gtkairo-pixmap) from-x from-y width height
     (to-medium gtkairo-pixmap) to-x to-y)
  (%medium-copy-area (ensure-pixmap-medium from-medium) from-x from-y
		     width height
		     (ensure-pixmap-medium to-medium) to-x to-y))
