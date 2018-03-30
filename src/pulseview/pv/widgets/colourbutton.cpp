/*
 * This file is part of the PulseView project.
 *
 * Copyright (C) 2013 Joel Holdsworth <joel@airwebreathe.org.uk>
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

#include "colourbutton.hpp"

#include <assert.h>

#include <QApplication>
#include <QPainter>
#include <QStyle>

namespace pv {
namespace widgets {

const int ColourButton::SwatchMargin = 7;

ColourButton::ColourButton(int rows, int cols, QWidget *parent, bool bgButton) :
	QPushButton("", parent),
	popup_(rows, cols, this),
	bgButton_(bgButton)
{
	connect(this, SIGNAL(clicked(bool)), this, SLOT(on_clicked(bool)));
	connect(&popup_, SIGNAL(selected(int, int)),
		this, SLOT(on_selected(int, int)));
	setStyleSheet("QPushButton { padding-right: 10px; }");
	setMinimumWidth(90);
	setMaximumWidth(90);
	setMinimumHeight(25);
	setMaximumHeight(25);
	this->setFocusPolicy(Qt::NoFocus);
	setIcon(QIcon(":/icons/sba_cmb_box_arrow.svg"));
	setIconSize(QSize(10, 6));
}

ColourPopup& ColourButton::popup()
{
	return popup_;
}

const QColor& ColourButton::colour() const
{
	return cur_colour_;
}

void ColourButton::set_colour(QColor colour)
{
	cur_colour_ = colour;

	const unsigned int rows = popup_.well_array().numRows();
	const unsigned int cols = popup_.well_array().numCols();

	for (unsigned int r = 0; r < rows; r++)
		for (unsigned int c = 0; c < cols; c++)
			if (popup_.well_array().cellBrush(r, c).color() == colour) {
				popup_.well_array().setSelected(r, c);
				popup_.well_array().setCurrent(r, c);
				return;
			}	
}

void ColourButton::set_palette(const QColor *const palette)
{
	assert(palette);

	const unsigned int rows = popup_.well_array().numRows();
	const unsigned int cols = popup_.well_array().numCols();

	for (unsigned int r = 0; r < rows; r++)
		for (unsigned int c = 0; c < cols; c++)
		{
			if(palette[r * cols + c].isValid()) {
				popup_.well_array().setCellBrush(r, c,
					QBrush(palette[r * cols + c]));
			}
			else {
				QColor col;
				if(bgButton_)
					col = QColor("#000000");
				else
					col = QColor("#795448");
				popup_.well_array().setCellBrush(r, c,
					QBrush(col));
			}

		}
}

void ColourButton::on_clicked(bool)
{
	popup_.set_position(mapToGlobal(rect().center()), Popup::Bottom);
	popup_.show();
}

void ColourButton::on_selected(int row, int col)
{
	cur_colour_ = popup_.well_array().cellBrush(row, col).color();
	selected(cur_colour_);
}

void ColourButton::paintEvent(QPaintEvent *event)
{
	QPushButton::paintEvent(event);

	QPainter p(this);
	p.setPen(QPen(cur_colour_));
	p.setBrush(QBrush(cur_colour_));
	p.drawRoundedRect(rect(), 4, 4);


	if(!this->icon().isNull())
		style()->drawItemPixmap(&p, rect(),Qt::AlignRight|Qt::AlignVCenter,
			this->icon().pixmap(iconSize()));
}

} // widgets
} // pv
