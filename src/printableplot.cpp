/*
 * Copyright 2018 Analog Devices, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNU Radio; see the file LICENSE.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#include "printableplot.h"
#include <QImage>
#include <QFileDialog>
#include "DisplayPlot.h"
#include <qwt_scale_widget.h>

using namespace adiscope;

PrintablePlot::PrintablePlot(QWidget *parent) :
        QwtPlot(parent),
        d_plotRenderer(new QwtPlotRenderer(this))
{
        dropBackground(true);
}

void PrintablePlot::dropBackground(bool drop)
{
        d_plotRenderer.setDiscardFlag(QwtPlotRenderer::DiscardBackground, drop);
        d_plotRenderer.setDiscardFlag(QwtPlotRenderer::DiscardCanvasBackground, drop);
}

void PrintablePlot::printPlot()
{
        legendDisplay = new QwtLegend(this);
        legendDisplay->setDefaultItemMode(QwtLegendData::Checkable);
        insertLegend(legendDisplay, QwtPlot::TopLegend);

        updateLegend();

        OscScaleDraw* sd = static_cast<OscScaleDraw*>(axisWidget(QwtPlot::xBottom)->scaleDraw());
        sd->setColor(Qt::white);
        sd->invalidateCache();

        QString fileName = QFileDialog::getSaveFileName(this,
                           tr("Save to"), "",
                           tr({"(*.png);;"}));
        QImage img(width(), height(), QImage::Format_RGBA8888);
        img.fill(Qt::black);
        QPainter painter(&img);
        d_plotRenderer.render(this, &painter, QRectF(0, 0, width(), height()));

        img.invertPixels(QImage::InvertRgb);

        painter.end();
        img.save(fileName, 0, -1);

        sd->setColor(Qt::gray);
        sd->invalidateCache();

        insertLegend(nullptr);
}
