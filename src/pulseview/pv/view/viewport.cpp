/*
 * This file is part of the PulseView project.
 *
 * Copyright (C) 2012 Joel Holdsworth <joel@airwebreathe.org.uk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 */

#include <cassert>
#include <cmath>
#include <algorithm>
#include <limits>

#include "signal.hpp"
#include "view.hpp"
#include "viewitempaintparams.hpp"
#include "viewport.hpp"
#include "ruler.hpp"

#include "../session.hpp"

#include <QApplication>
#include <QMouseEvent>

using std::abs;
using std::back_inserter;
using std::copy;
using std::dynamic_pointer_cast;
using std::max;
using std::min;
using std::none_of;
using std::numeric_limits;
using std::shared_ptr;
using std::stable_sort;
using std::vector;

namespace pv {
namespace view {

Viewport::Viewport(View &parent) :
	ViewWidget(parent),
	pinch_zoom_active_(false),
	timeTriggerSample(0),
	timeTriggerPixel(0),
	timeTriggerActive(false),
	cursorsActive(false),
	cursorsPixelValues(std::pair<int, int>(0,0))
{
	/* Permits the QWidget to have a visible background */
	setAttribute(Qt::WA_StyledBackground, true);

	/* TODO: Why isn't it picking up the application-wide stylesheet? */
	setStyleSheet(qApp->styleSheet());
}

void Viewport::setTimeTriggerPosActive(bool active)
{
	timeTriggerActive = active;
}

bool Viewport::getTimeTriggerActive()
{
	return timeTriggerActive;
}

shared_ptr<ViewItem> Viewport::get_mouse_over_item(const QPoint &pt)
{
	const ViewItemPaintParams pp(rect(), view_.scale(), view_.offset(), view_.divisionCount());
	const vector< shared_ptr<ViewItem> > items(this->items());
	for (auto i = items.rbegin(); i != items.rend(); i++)
		if ((*i)->enabled() &&
			(*i)->hit_box_rect(pp).contains(pt))
			return *i;
	return nullptr;
}

void Viewport::disableDrag()
{
	dragEnabled = false;
}

void Viewport::enableDrag()
{
	dragEnabled = true;
}

boost::optional<pv::util::Timestamp>  Viewport::getDragOffset()
{
	return drag_offset_;
}

void Viewport::item_hover(const shared_ptr<ViewItem> &item)
{
	if (item && item->is_draggable())
		setCursor(dynamic_pointer_cast<RowItem>(item) ?
			Qt::SizeVerCursor : Qt::SizeHorCursor);
	else
		unsetCursor();
}

void Viewport::drag()
{
	if(dragEnabled)
	{
		drag_offset_ = view_.offset();
		drag_v_offset_ = view_.owner_visual_v_offset();
	}
}

void Viewport::drag_by(const QPoint &delta)
{
	if(dragEnabled)
	{
		if (drag_offset_ == boost::none)
			return;

		view_.set_scale_offset(view_.scale(),
			(*drag_offset_ - delta.x() * view_.scale() / (geometry().width() / divisionCount)));
		//view_.set_v_offset(-drag_v_offset_ - delta.y());
		update();
		if( getTimeTriggerActive() )
			Q_EMIT plotChanged(false);
	}
}

void Viewport::drag_release()
{
	drag_offset_ = boost::none;
}

vector< shared_ptr<ViewItem> > Viewport::items()
{
	vector< shared_ptr<ViewItem> > items;
	const std::vector< shared_ptr<ViewItem> > view_items(
		view_.list_by_type<ViewItem>());
	copy(view_items.begin(), view_items.end(), back_inserter(items));
	const vector< shared_ptr<TimeItem> > time_items(view_.time_items());
	copy(time_items.begin(), time_items.end(), back_inserter(items));
	return items;
}

bool Viewport::touch_event(QTouchEvent *event)
{
	QList<QTouchEvent::TouchPoint> touchPoints = event->touchPoints();

	if (touchPoints.count() != 2) {
		pinch_zoom_active_ = false;
		return false;
	}

	const QTouchEvent::TouchPoint &touchPoint0 = touchPoints.first();
	const QTouchEvent::TouchPoint &touchPoint1 = touchPoints.last();

	if (!pinch_zoom_active_ ||
	    (event->touchPointStates() & Qt::TouchPointPressed)) {
		double scale  = view_.scale() /(view_.viewport()->size().width() / view_.divisionCount());
		pinch_offset0_ = (view_.offset() + scale * touchPoint0.pos().x()).convert_to<double>();
		pinch_offset1_ = (view_.offset() + scale * touchPoint1.pos().x()).convert_to<double>();
		pinch_zoom_active_ = true;
	}

	double w = touchPoint1.pos().x() - touchPoint0.pos().x();
	if (abs(w) >= 1.0) {
		const double scale =
			fabs((pinch_offset1_ - pinch_offset0_) / w);
		double offset = pinch_offset0_ - touchPoint0.pos().x() * scale;
		if (scale > 0)
			view_.set_scale_offset(scale, offset);
	}

	if (event->touchPointStates() & Qt::TouchPointReleased) {
		pinch_zoom_active_ = false;

		if (touchPoint0.state() & Qt::TouchPointReleased) {
			// Primary touch released
			drag_release();
		} else {
			// Update the mouse down fields so that continued
			// dragging with the primary touch will work correctly
			mouse_down_point_ = touchPoint0.pos().toPoint();
			drag();
		}
	}

	return true;
}

void Viewport::paintEvent(QPaintEvent*)
{
	vector< shared_ptr<RowItem> > row_items(view_.list_by_type<RowItem>());
	assert(none_of(row_items.begin(), row_items.end(),
		[](const shared_ptr<RowItem> &r) { return !r; }));

	stable_sort(row_items.begin(), row_items.end(),
		[](const shared_ptr<RowItem> &a, const shared_ptr<RowItem> &b) {
			return a->point(QRect()).y() < b->point(QRect()).y(); });

	const vector< shared_ptr<TimeItem> > time_items(view_.time_items());
	assert(none_of(time_items.begin(), time_items.end(),
		[](const shared_ptr<TimeItem> &t) { return !t; }));

	QPainter p(this);
	p.setRenderHint(QPainter::Antialiasing);

	const ViewItemPaintParams pp(rect(), view_.scale(), view_.offset(), view_.divisionCount());

	for (const shared_ptr<TimeItem> t : time_items)
		t->paint_back(p, pp);
	for (const shared_ptr<RowItem> r : row_items)
//		if (!r->isInitial())
			r->paint_back(p, pp);

	for (const shared_ptr<TimeItem> t : time_items)
		t->paint_mid(p, pp);
	for (const shared_ptr<RowItem> r : row_items)
		if (r->isVisible())
			r->paint_mid(p, pp);

	paint_grid(p, pp);

	for (const shared_ptr<RowItem> r : row_items)
		if (r->isVisible())
			r->paint_fore(p, pp);

	p.setRenderHint(QPainter::Antialiasing, false);
	for (const shared_ptr<TimeItem> t : time_items)
		t->paint_fore(p, pp);

	if( timeTriggerActive && !(view_.ruler_->get_offset() > 0 && timeTriggerSample == 0)){
		paint_time_trigger_line(p, pp, timeTriggerSample);
	}

	if( cursorsActive ){
		paint_cursors(p, pp);
	}

	if( view_.session().is_screen_mode())
		paint_last_sample_cursor(p, pp);
	p.end();
}

void Viewport::paint_cursors(QPainter &p, const ViewItemPaintParams &pp)
{
	QPen cursorsLinePen = QPen(QColor(155, 155, 155), 1, Qt::DashLine);
	p.setPen(cursorsLinePen);
	const int y = view_.owner_visual_v_offset();
	const int h = pp.height();
	int row_count = view_.height() / divisionHeight;

	QPoint p1 = QPoint(cursorsPixelValues.first, y);
	QPoint p2 = QPoint(cursorsPixelValues.first, y + h * row_count);
	p.drawLine(p1, p2);

	p1 = QPoint(cursorsPixelValues.second, y);
	p2 = QPoint(cursorsPixelValues.second, y + h * row_count);
	p.drawLine(p1, p2);
}

void Viewport::setTimeTriggerSample(int sample)
{
	if( sample != timeTriggerSample )
	{
		timeTriggerSample = sample;
		view_.time_item_appearance_changed(true, true);
	}
}

void Viewport::cursorValueChanged_1(int pos)
{
	cursorsPixelValues.first = pos;
	view_.time_item_appearance_changed(true, true);
}

void Viewport::cursorValueChanged_2(int pos)
{
	cursorsPixelValues.second = pos;
	view_.time_item_appearance_changed(true, true);
}

int Viewport::getTimeTriggerSample() const
{
	return timeTriggerSample;
}

void Viewport::paint_time_trigger_line(QPainter &p, const ViewItemPaintParams &pp, int sample_index)
{
	double samplerate = view_.session().get_samplerate();
	int px;
	if( samplerate != 1 ) {
		const double samples_per_pixel = samplerate * pp.scale();
		const double pixels_offset = pp.pixels_offset();
		px = (sample_index / samples_per_pixel - pixels_offset);
		if( px != timeTriggerPixel) {
			timeTriggerPixel = px;
			repaintTriggerHandle(timeTriggerPixel);
		}
	}

	QPen pen = QPen(QColor(74, 100, 255));
	p.setPen(pen);
	const int y = view_.owner_visual_v_offset();
	const int h = pp.height();
	int row_count = view_.height() / divisionHeight;

	QPoint p1 = QPoint(timeTriggerPixel, y);
	QPoint p2 = QPoint(timeTriggerPixel, y + h * row_count);
	p.drawLine(p1, p2);
}

void Viewport::paint_last_sample_cursor(QPainter &p, const ViewItemPaintParams &pp)
{
	int sample_index = view_.session().get_logic_active_sample();
	double samplerate = view_.session().get_samplerate();
	int px;
	if( samplerate != 1 ) {
		const double samples_per_pixel = samplerate * pp.scale();
		const double pixels_offset = pp.pixels_offset();
		px = (sample_index / samples_per_pixel - pixels_offset) + pp.left();
	}

	QPen pen = QPen(QColor("white"));
	p.setPen(pen);
	const int y = view_.owner_visual_v_offset();
	const int h = pp.height();
	int row_count = view_.height() / divisionHeight;

	QPoint p1 = QPoint(px, y);
	QPoint p2 = QPoint(px, y + h * row_count);
	p.drawLine(p1, p2);
}

void Viewport::paint_grid(QPainter &p, const ViewItemPaintParams &pp)
{
	const int x = pp.left();
	const int w = pp.right() -pp.left();
	const int h = pp.height();
	const int y = view_.owner_visual_v_offset();//pp.top();

	int division_height = divisionHeight;
	int division_count = divisionCount;
	int division_offset = divisionOffset;

	int division_width = w / division_count;    
	int row_count = view_.height() / division_height;

	QPointF p1, p2;

	p.setRenderHint(QPainter::Antialiasing, false);
	QPen pen = QPen(QColor(255, 255, 255, 30*256/100));
	for (int i = 0; i <= division_count; i++) {
		pen.setStyle((i % 2) ? Qt::SolidLine : Qt::DashLine);
		p.setPen(pen);

		p1 = QPointF(x + w*i/division_count, y);
		p2 = QPointF(x + w*i/division_count, y + h * row_count);
		view_.setGridPosition(i, x + w*i/division_count);
		p.drawLine(p1, p2);
	}
	p.setRenderHint(QPainter::Antialiasing, true);    
	paint_axis(p,pp,pp.bottom());
   /* for (int i = 0; i <= row_count; i++) {
        if(y + divisionOffset+ division_height * i != 0)
            paint_axis(p, pp, y + divisionOffset + division_height * i);
	}*/
}

void Viewport::paint_axis(QPainter &p, const ViewItemPaintParams &pp, int y)
{
	p.setRenderHint(QPainter::Antialiasing, false);

	p.setPen(QPen(QColor(255, 255, 255, 30*256/100)));
	p.drawLine(QPointF(pp.left(), y), QPointF(pp.right(), y));

	p.setRenderHint(QPainter::Antialiasing, true);
}

void Viewport::mouseDoubleClickEvent(QMouseEvent *event)
{
	assert(event);

	if (event->buttons() & Qt::LeftButton)
		view_.zoom(2.0, event->x());
	else if (event->buttons() & Qt::RightButton)
		view_.zoom(-2.0, event->x());
}

void Viewport::wheelEvent(QWheelEvent *event)
{
	assert(event);

	if (event->orientation() == Qt::Vertical) {
		if (event->modifiers() & Qt::ControlModifier) {
			// Vertical scrolling with the control key pressed
			// is intrepretted as vertical scrolling
		/*	view_.set_v_offset(-view_.owner_visual_v_offset() -
				(event->delta() * height()) / (8 * 120));*/
		} else {
			// Vertical scrolling is interpreted as zooming in/out
			view_.zoom(event->delta() / 120, event->x());
		}
	} else if (event->orientation() == Qt::Horizontal) {
		// Horizontal scrolling is interpreted as moving left/right
		view_.set_scale_offset(view_.scale(),
			event->delta() * view_.scale() + view_.offset());
	}
}

bool Viewport::getCursorsActive() const
{
	return cursorsActive;
}

void Viewport::setCursorsActive(bool value)
{
	cursorsActive = value;
	view_.time_item_appearance_changed(true, true);
}

std::pair<int, int> Viewport::getCursorsPixelValues() const
{
	return cursorsPixelValues;
}

void Viewport::setCursorsPixelValues(const std::pair<int, int> &value)
{
	cursorsPixelValues = value;
}

int Viewport::getTimeTriggerPixel() const
{
	return timeTriggerPixel;
}

void Viewport::setTimeTriggerPixel(int value)
{
	timeTriggerPixel = value;
}

int Viewport::getDivisionOffset() const
{
	return divisionOffset;
}

void Viewport::setDivisionOffset(int value)
{
	divisionOffset = value;
}

int Viewport::getDivisionCount() const
{
    return divisionCount;
}

void Viewport::setDivisionCount(int value)
{
    divisionCount = value;
}

int Viewport::getDivisionHeight() const
{
    return divisionHeight;
}

void Viewport::setDivisionHeight(int value)
{
    divisionHeight = value;
}

} // namespace view
} // namespace pv
